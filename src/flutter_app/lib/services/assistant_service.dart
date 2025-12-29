import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../ai_tools/tool_definitions.dart';
import '../ai_tools/tool_registry.dart';
import '../models/ai_models.dart';
import '../services/data_service.dart';
import 'ai_wrapper.dart'; 

class AssistantService extends ChangeNotifier {
  final DataService _dataService;
  final ToolRegistry _toolRegistry;
  final AIModelWrapper _modelWrapper;
  
  ChatSessionWrapper? _chat;
  
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isVoiceEnabled = false; 
  String _lastWords = '';
  String _lastError = '';

  final List<ChatMessage> _messages = [];
  final List<ProposedAction> _pendingActions = []; 
  final List<ProposedAction> _executedActions = [];
  
  bool _isLoading = false;
  bool _isThinkingMode = false;

  AssistantService(this._dataService, this._toolRegistry, this._modelWrapper) {
    _initTts();
    _startNewChat();
    _loadHistory();
  }

  Future<void> _loadHistory() async {
    _isLoading = true;
    final history = await _dataService.getChatHistory('assistant');
    _messages.addAll(history);
    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    _messages.clear();
    _chat = null;
    _startNewChat();
    await _dataService.clearChatHistory('assistant');
    notifyListeners();
  }

  List<ChatMessage> get messages => _messages;
  List<ProposedAction> get pendingActions => _pendingActions;
  List<ProposedAction> get executedActions => _executedActions;
  bool get isListening => _isListening;
  bool get isLoading => _isLoading;
  bool get isThinkingMode => _isThinkingMode;
  String get currentSpeech => _lastWords;
  bool get isVoiceEnabled => _isVoiceEnabled;

  Future<void> _initTts() async {
    if (Platform.isIOS) {
      await _flutterTts.setSharedInstance(true);
      await _flutterTts.setIosAudioCategory(IosTextToSpeechAudioCategory.playback,
          [
            IosTextToSpeechAudioCategoryOptions.allowBluetooth,
            IosTextToSpeechAudioCategoryOptions.allowBluetoothA2DP,
            IosTextToSpeechAudioCategoryOptions.mixWithOthers
          ],
          IosTextToSpeechAudioMode.voicePrompt
      );
    }
    await _flutterTts.awaitSpeakCompletion(true);
    await _flutterTts.setLanguage("en-US");
  }

  void _startNewChat() {
    final projectContext = _dataService.projects.map((p) => "${p.title} (ID: ${p.id})").join(", ");
    
    final systemInstruction = Content.text(
        "You are an intelligent assistant integrated into a task management app. "
        "You have two modes of operation controlled by the user: 'Standard' and 'Thinking'.\n"
        "- Standard Mode: Be concise. Execute tools immediately. Focus on getting things done.\n"
        "- Thinking Mode: Act as a mentor. Analyze the user's request deeply. Explain your reasoning. "
        "Verify assumptions before executing tools. Use the 'save_memory' tool to remember important user context.\n\n"
        "Current Projects Context: $projectContext.\n\n"
        "IMPORTANT LANGUAGE RULE: The user may speak in German or English. "
        "You must UNDERSTAND their intent in either language, but ALWAYS RESPOND IN ENGLISH. "
        "Preserve the User's original language for content (e.g., Task Titles).");

    _chat = _modelWrapper.startChat(
      history: [
        systemInstruction, 
      ],
    );
  }

  void toggleThinking() {
    _isThinkingMode = !_isThinkingMode;
    notifyListeners();
  }

  Future<void> toggleRecording() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      if (_lastWords.isNotEmpty) {
        sendMessage(_lastWords);
      }
    } else {
      bool available = false;
      try {
        available = await _speech.initialize(
          onError: (error) {
            _lastError = error.errorMsg;
            notifyListeners();
          },
        );
      } catch (e) {
        available = false;
      }

      if (available) {
        _isListening = true;
        _lastWords = '';
        notifyListeners();
        _speech.listen(onResult: (result) {
          _lastWords = result.recognizedWords;
          notifyListeners();
        });
      } else {
        _messages.add(ChatMessage(text: "Microphone unavailable.", isUser: false));
        notifyListeners();
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    print("[VERIFY_FLOW] Service Receive: $text (Thinking: $_isThinkingMode)");

    final userMsg = ChatMessage(text: text, isUser: true);
    _messages.add(userMsg);
    await _dataService.saveChatMessage(userMsg, 'assistant');

    _isLoading = true;
    notifyListeners();

    try {
      await _handleUnifiedMessage(text);
    } catch (e) {
      _messages.add(ChatMessage(text: "Error: $e", isUser: false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleUnifiedMessage(String text) async {
      if (_chat == null) _startNewChat();

      String fullPrompt;
      if (_isThinkingMode) {
        fullPrompt = "[System: THINKING MODE ENABLED. Deeply analyze this request. Explain your plan. Act as a Mentor.]\nUser: $text";
      } else {
        fullPrompt = "[System: THINKING MODE DISABLED. Be concise. Execute tools immediately if clear.]\nUser: $text";
      }

      var currentContent = Content.text(fullPrompt);
      var iterations = 0;
      const maxIterations = 5;

      while (iterations < maxIterations) {
        final response = await _chat!.sendMessage(currentContent);
        
        if (response.functionCalls.isNotEmpty) {
          final functionResponseParts = <FunctionResponse>[];
          
          for (var call in response.functionCalls) {
             try {
                if (call.name == 'save_memory') {
                   final result = await _toolRegistry.executeTool(call.name, call.args);
                   functionResponseParts.add(FunctionResponse(call.name, result));
                } else {
                   _pendingActions.add(ProposedAction(
                    description: _toolRegistry.describeAction(call.name, call.args),
                    toolName: call.name,
                    toolArgs: call.args,
                  ));
                  notifyListeners();
                  
                  functionResponseParts.add(FunctionResponse(
                    call.name,
                    {'result': 'pending', 'message': 'Action proposed to user. Waiting for approval.'},
                  ));
                }
             } catch (e) {
                functionResponseParts.add(FunctionResponse(call.name, {'result': 'error', 'message': e.toString()}));
             }
          }
          
          if (functionResponseParts.isNotEmpty) {
             currentContent = Content.multi(functionResponseParts);
             iterations++;
             continue; 
          }
        }
        
        final textResponse = response.text;
        if (textResponse != null && textResponse.isNotEmpty) {
          final aiMsg = ChatMessage(text: textResponse, isUser: false);
          _messages.add(aiMsg);
          await _dataService.saveChatMessage(aiMsg, 'assistant');
          if (_isVoiceEnabled) _flutterTts.speak(textResponse);
        }
        break;
      }
  }

  Future<void> acceptAction(ProposedAction action) async {
    try {
      await _toolRegistry.executeTool(action.toolName, action.toolArgs);
      action.isExecuted = true;
      if (!_executedActions.contains(action)) {
        _executedActions.add(action);
      }
      notifyListeners();
    } catch (e) {
      debugPrint("Error executing action: $e");
    }
  }

  void declineAction(ProposedAction action) {
    _pendingActions.remove(action);
    notifyListeners();
  }

  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    if (!_isVoiceEnabled) _flutterTts.stop();
    notifyListeners();
  }
}