import 'package:flutter/foundation.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import '../ai_tools/tool_registry.dart';
import '../models/ai_models.dart';
import '../services/data_service.dart';
import 'ai_wrapper.dart'; 
import 'tts_service.dart';

class AssistantService extends ChangeNotifier {
  final DataService _dataService;
  final ToolRegistry _toolRegistry;
  final AIModelWrapper _modelWrapper;
  
  ChatSessionWrapper? _chat;
  
  final SpeechToText _speech = SpeechToText();
  final TtsService _ttsService = TtsService();
  bool _isListening = false;
  bool _isVoiceEnabled = true; 
  String _lastWords = '';
  String _lastError = '';

  final List<ChatMessage> _messages = [];
  final List<ProposedAction> _pendingActions = []; 
  final List<ProposedAction> _executedActions = [];
  
  bool _isLoading = false;
  bool _isThinkingMode = false;
  String _draftMessage = '';

  String? _currentConversationId;

  AssistantService(this._dataService, this._toolRegistry, this._modelWrapper);

  // --- Conversation Management ---

  String? get currentConversationId => _currentConversationId;

  Future<void> loadConversation(String conversationId) async {
    if (_currentConversationId == conversationId) return;

    _isLoading = true;
    _currentConversationId = conversationId;
    _messages.clear();
    _pendingActions.clear();
    _executedActions.clear();
    notifyListeners();

    final history = await _dataService.getChatHistory('assistant', conversationId: conversationId);
    _messages.addAll(history);
    
    await _startNewChat(history: history); 
    
    _isLoading = false;
    notifyListeners();
  }

  Future<String> createNewConversation(String title) async {
    final id = _dataService.createConversation(title);
    await loadConversation(id);
    return id;
  }

  Future<void> clearHistory() async {
    if (_currentConversationId == null) return;
    _messages.clear();
    _chat = null;
    await _startNewChat();
    await _dataService.clearChatHistory('assistant', conversationId: _currentConversationId);
    notifyListeners();
  }

  @override
  void dispose() {
    _ttsService.dispose();
    super.dispose();
  }

  // --- Properties ---

  List<ChatMessage> get messages => _messages;
  List<ProposedAction> get pendingActions => _pendingActions;
  List<ProposedAction> get executedActions => _executedActions;
  bool get isListening => _isListening;
  bool get isLoading => _isLoading;
  bool get isThinkingMode => _isThinkingMode;
  String get currentSpeech => _lastWords;
  bool get isVoiceEnabled => _isVoiceEnabled;
  String get draftMessage => _draftMessage;

  void setDraftMessage(String text) {
    _draftMessage = text;
  }

  // --- Internal Logic ---

  Future<void> _startNewChat({List<ChatMessage>? history}) async {
    final knowledgeList = await _dataService.getAllKnowledge();
    final knowledgeContext = knowledgeList.map((k) => "- ${k.content}").join("\n");

    final projectContext = _dataService.projects.map((p) {
      final tasks = p.tasks.map((t) {
        final subtasks = t.subtasks.map((s) => "    - [${s.isCompleted ? 'X' : ' '}] ${s.title} (ID: ${s.id})").join("\n");
        return "  - [${t.isCompleted ? 'X' : ' '}] ${t.title} (ID: ${t.id})\n$subtasks";
      }).join("\n");
      return "Project: ${p.title} (ID: ${p.id})\n$tasks";
    }).join("\n\n");
    
    final systemInstruction = Content.text(
        "You are an intelligent assistant integrated into a task management app. "
        "You have two modes of operation controlled by the user: 'Standard' and 'Thinking'.\n"
        "- Standard Mode: Be concise. Execute tools immediately. Focus on getting things done.\n"
        "- Thinking Mode: Act as a mentor. Analyze the user's request deeply. Explain your reasoning. "
        "Verify assumptions before executing tools. Use the 'save_memory' tool to remember important user context.\n\n"
        "=== USER KNOWLEDGE BASE ===\n$knowledgeContext\n\n"
        "=== CURRENT PROJECTS & TASKS ===\n$projectContext\n\n"
        "IMPORTANT LANGUAGE RULE: The user may speak in German or English. "
        "You must DETECT the language of the user's current message and RESPOND IN THE SAME LANGUAGE. "
        "However, if the user asks to create content (like a Task Title), preserve that specific text exactly as given, regardless of the surrounding conversation language.\n\n"
        "VOICE OPTIMIZATION: Your responses are read aloud via Text-to-Speech. "
        "1. DO NOT use markdown formatting like '**' (bold) or '###' (headlines). These symbols are not voice-friendly. "
        "2. Use natural sentence structures and punctuation (commas, periods) to guide the speech rhythm. "
        "3. Keep lists simple and conversational (e.g., 'First... Second...'). "
        "4. Focus on clear, structured text that is easy to listen to.");

    _chat = _modelWrapper.startChat(
      history: [systemInstruction], 
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
    if (_currentConversationId == null) {
      await createNewConversation("General Chat");
    }

    print("[VERIFY_FLOW] Service Receive: $text (Thinking: $_isThinkingMode)");

    _draftMessage = '';
    notifyListeners(); 

    final userMsg = ChatMessage(
      text: text, 
      isUser: true, 
      conversationId: _currentConversationId
    );
    
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
      if (_chat == null) await _startNewChat();

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
        final aiResponse = await _chat!.sendMessage(currentContent);
        
        if (aiResponse.functionCalls.isNotEmpty) {
          final functionResponseParts = <FunctionResponse>[];
          
          for (var call in aiResponse.functionCalls) {
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
             final partsToSendBack = functionResponseParts.cast<Part>();
             currentContent = Content.multi(partsToSendBack);
             iterations++;
             continue; 
          }
        }
        
        final textResponse = aiResponse.text;
        if (textResponse != null && textResponse.isNotEmpty) {
          final aiMsg = ChatMessage(
            text: textResponse, 
            isUser: false,
            conversationId: _currentConversationId,
          );
          _messages.add(aiMsg);
          await _dataService.saveChatMessage(aiMsg, 'assistant');
          
          if (_isVoiceEnabled) {
            print("[ASSISTANT] Voice is enabled. Speaking response...");
            _speakResponse(textResponse);
          } else {
            print("[ASSISTANT] Voice is disabled. Skipping TTS.");
          }
        }
        break;
      }
  }

  Future<void> _speakResponse(String text) async {
    try {
      // Clean text for TTS: Remove markdown artifacts
      final cleanText = text
          .replaceAll('**', '') // Remove bold
          .replaceAll('###', '') // Remove H3
          .replaceAll('##', '') // Remove H2
          .replaceAll('`', '') // Remove code ticks
          .replaceAll(RegExp(r'\[(.*?)\]\(.*?\)'), r'\1'); // Keep link text, remove URL

      // Simple heuristic for language detection
      final germanIndicators = ['der', 'die', 'das', 'und', 'ist', 'nicht', 'hallo', 'guten'];
      final lowerText = cleanText.toLowerCase();
      final isGerman = germanIndicators.any((word) => lowerText.contains(RegExp(r'\b' + word + r'\b')));
      
      final languageCode = isGerman ? 'de-DE' : 'en-US';
      
      final url = await _ttsService.generateAndGetUrl(
        text: cleanText, 
        languageCode: languageCode,
      );
      await _ttsService.playUrl(url);
    } catch (e) {
      debugPrint("Error playing voice: $e");
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
    if (!_isVoiceEnabled) _ttsService.stop();
    notifyListeners();
  }
}