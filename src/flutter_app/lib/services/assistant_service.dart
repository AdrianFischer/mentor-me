import 'dart:io';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../ai_tools/tool_definitions.dart';
import '../ai_tools/tool_registry.dart';
import '../models/ai_models.dart';
import '../services/data_service.dart';
import '../config.dart';

class ThinkingHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  final bool Function() _isThinkingMode;

  ThinkingHttpClient(this._isThinkingMode);

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) async {
    if (_isThinkingMode() && request is http.Request && request.url.path.contains('generateContent')) {
       try {
         final body = jsonDecode(request.body) as Map<String, dynamic>;
         if (body['generationConfig'] == null) {
            body['generationConfig'] = {};
         }
         // Inject Thinking Config
         // According to search: "generationConfig": { "thinkingConfig": { "thinkingLevel": "HIGH" } }
         // Also adding includeThoughts just in case useful for debug/future
         (body['generationConfig'] as Map<String, dynamic>)['thinkingConfig'] = {
            'thinkingLevel': 'HIGH',
            'includeThoughts': true 
         };

         final newBody = jsonEncode(body);
         request.body = newBody;
         request.headers['content-length'] = utf8.encode(newBody).length.toString();
         debugPrint("[ThinkingHttpClient] Injected thinkingConfig: HIGH");
       } catch (e) {
         debugPrint("[ThinkingHttpClient] Failed to inject thinking param: $e");
       }
    }
    return _inner.send(request);
  }
}

class AssistantService extends ChangeNotifier {
  final DataService _dataService;
  final ToolRegistry _toolRegistry;
  
  // Gemini
  late final GenerativeModel _model;
  ChatSession? _chat;
  
  // Mentor Mode
  late final GenerativeModel _mentorModel;
  ChatSession? _mentorChat;
  final List<ChatMessage> _mentorMessages = [];
  bool _isMentorMode = false;

  String _apiKey = '';
  
  // Speech & TTS
  final SpeechToText _speech = SpeechToText();
  final FlutterTts _flutterTts = FlutterTts();
  bool _isListening = false;
  bool _isVoiceEnabled = false; // TTS Toggle
  String _lastWords = '';
  String _lastError = '';

  // State
  final List<ChatMessage> _messages = [];
  final List<ProposedAction> _pendingActions = []; 
  final List<ProposedAction> _executedActions = [];
  
  bool _isLoading = false;
  bool _isThinkingMode = false; // "Thinking" Toggle

  AssistantService(this._dataService, this._toolRegistry) {
    _initGemini();
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
    if (Config.hasGeminiKey) _startNewChat();
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

  void _initGemini() {
    _apiKey = Config.geminiApiKey;
    
    final tools = ToolDefinitions.tools.map((t) {
       return FunctionDeclaration(
         t['name'],
         t['description'],
         Schema(SchemaType.object, properties: {
           for (var entry in (t['parameters']['properties'] as Map).entries)
             entry.key: Schema(
               entry.value['type'] == 'integer' ? SchemaType.integer 
               : entry.value['type'] == 'boolean' ? SchemaType.boolean 
               : SchemaType.string,
               description: entry.value['description']
             )
         }, requiredProperties: List<String>.from(t['parameters']['required']))
       );
    }).toList();

    if (!Config.hasGeminiKey) {
      debugPrint('Warning: No API Key provided. Using Mock Mode.');
    }

    // Unified Model
    _model = GenerativeModel(
      model: 'gemini-2.0-flash-thinking-exp-01-21',
      apiKey: _apiKey.isNotEmpty ? _apiKey : 'dummy-key',
      tools: [Tool(functionDeclarations: tools)],
      httpClient: ThinkingHttpClient(() => _isThinkingMode),
    );

    _initTts();

    if (Config.hasGeminiKey) {
       _startNewChat();
    }
  }

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
    
    // Unified System Prompt
    _chat = _model.startChat(history: [
      Content.text(
          "You are an intelligent assistant integrated into a task management app. "
          "You have two modes of operation controlled by the user: 'Standard' and 'Thinking'.\n"
          "- Standard Mode: Be concise. Execute tools immediately. Focus on getting things done.\n"
          "- Thinking Mode: Act as a mentor. Analyze the user's request deeply. Explain your reasoning. "
          "Verify assumptions before executing tools. Use the 'save_memory' tool to remember important user context.\n\n"
          "Current Projects Context: $projectContext.\n\n"
          "IMPORTANT LANGUAGE RULE: The user may speak in German or English. "
          "You must UNDERSTAND their intent in either language, but ALWAYS RESPOND IN ENGLISH. "
          "Preserve the User's original language for content (e.g., Task Titles).")
    ]);
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
      if (!Config.hasGeminiKey) {
        await _handleMockMode(text);
      } else {
        await _handleUnifiedMessage(text);
      }
    } catch (e) {
      _messages.add(ChatMessage(text: "Error: $e", isUser: false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleUnifiedMessage(String text) async {
      if (_chat == null) _startNewChat();

      // Dynamic Guidance based on Mode
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
          // Tool Execution Logic
          final functionResponses = <Content>[];
          for (var call in response.functionCalls) {
             try {
                // If Thinking Mode, we might want to propose everything? 
                // For now, we stick to the 'Review Layer' pattern (ProposedAction) for critical stuff, 
                // or just execute safe stuff.
                // The current app logic proposes actions for review. We keep that.
                
                // EXCEPT for 'save_memory' which is usually automatic in mentor mode.
                if (call.name == 'save_memory') {
                   // Execute immediately
                   final result = await _toolRegistry.executeTool(call.name, call.args);
                   functionResponses.add(Content.functionResponse(call.name, result));
                } else {
                   // Propose
                   _pendingActions.add(ProposedAction(
                    description: _toolRegistry.describeAction(call.name, call.args),
                    toolName: call.name,
                    toolArgs: call.args,
                  ));
                  notifyListeners();
                  
                  // Tell model we are waiting
                  functionResponses.add(Content.functionResponse(
                    call.name,
                    {'result': 'pending', 'message': 'Action proposed to user. Waiting for approval.'},
                  ));
                }
             } catch (e) {
                functionResponses.add(Content.functionResponse(call.name, {'result': 'error', 'message': e.toString()}));
             }
          }
          
          for (var i = 0; i < functionResponses.length; i++) {
            if (i == functionResponses.length - 1) {
              currentContent = functionResponses[i];
            } else {
              await _chat!.sendMessage(functionResponses[i]);
            }
          }
          iterations++;
          continue;
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

  Future<void> _handleMockMode(String text) async {
        await Future.delayed(const Duration(seconds: 1));
        
        if (_isThinkingMode) {
             _messages.add(ChatMessage(text: "[Mock Thinking] That is a profound question. Let's break it down...", isUser: false));
             return;
        }

        // Mock Logic ... (Simplified for brevity as it was just copy-paste)
        _messages.add(ChatMessage(text: "I am in Mock Mode (Unified).", isUser: false));
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
  
  bool get isVoiceEnabled => _isVoiceEnabled;
}

