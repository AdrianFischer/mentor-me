import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
import 'package:flutter_tts/flutter_tts.dart';
import '../ai_tools/tool_definitions.dart';
import '../ai_tools/tool_registry.dart';
import '../models/ai_models.dart';
import '../services/data_service.dart';
import '../config.dart';

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
  final List<ChatMessage> _assistantMessages = [];
  final List<ProposedAction> _pendingActions = []; // Kept for backward compat, but effectively unused
  final List<ProposedAction> _executedActions = []; // New: Track history
  bool _isLoading = false;

  AssistantService(this._dataService, this._toolRegistry) {
    _initGemini();
    _loadHistory();
    // _initSpeech(); // Delay initialization to avoid crash on startup
  }

  Future<void> _loadHistory() async {
    _isLoading = true;
    // We don't notify here to avoid build errors during init, but usually safe if provider is reading.
    
    final assistantHistory = await _dataService.getChatHistory('assistant');
    _assistantMessages.addAll(assistantHistory);
    
    final mentorHistory = await _dataService.getChatHistory('mentor');
    _mentorMessages.addAll(mentorHistory);

    _isLoading = false;
    notifyListeners();
  }

  Future<void> clearHistory() async {
    final mode = _isMentorMode ? 'mentor' : 'assistant';
    if (_isMentorMode) {
      _mentorMessages.clear();
      _mentorChat = null; // Reset chat session
    } else {
      _assistantMessages.clear();
      _chat = null;
      if (Config.hasGeminiKey) _startNewChat(); // Restart assistant chat
    }
    
    await _dataService.clearChatHistory(mode);
    notifyListeners();
  }

  List<ChatMessage> get messages => _isMentorMode ? _mentorMessages : _assistantMessages;
  List<ProposedAction> get pendingActions => _pendingActions;
  List<ProposedAction> get executedActions => _executedActions;
  bool get isListening => _isListening;
  bool get isLoading => _isLoading;
  bool get isMentorMode => _isMentorMode;
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
      // We will handle this in sendMessage
    }

    _model = GenerativeModel(
      model: 'gemini-2.5-flash',
      apiKey: _apiKey.isNotEmpty ? _apiKey : 'dummy-key', // GenerativeModel requires non-empty key
      tools: [Tool(functionDeclarations: tools)],
    );

    // Filter tools for Mentor (only save_memory)
    final mentorTools = tools.where((t) => t.name == 'save_memory').toList();

    _mentorModel = GenerativeModel(
      model: Config.mentorModelName,
      apiKey: _apiKey.isNotEmpty ? _apiKey : 'dummy-key',
      tools: [Tool(functionDeclarations: mentorTools)],
    );
    
    _initTts();

    // Only start chat if we have a key, otherwise we'll mock it
    if (Config.hasGeminiKey) {
       _startNewChat();
       // Mentor chat is started lazily or now? Let's start it lazily when needed or now.
       // _startMentorChat(); // We'll start it when switching or now.
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
    // Optionally set voice if we want "best available"
    // var voices = await _flutterTts.getVoices;
    // print(voices); 
  }

  void _initSpeech() async {
    // We don't await here to avoid blocking constructor, but in real app handle permission/error state better
    try {
      await _speech.initialize();
    } catch (e) {
      debugPrint('Speech initialization failed: $e');
    }
  }

  void _startNewChat() {
    // Provide context about current projects
    final projectContext = _dataService.projects.map((p) => "${p.title} (ID: ${p.id})").join(", ");
    
    _chat = _model.startChat(history: [
      Content.text("You are a helpful assistant for a task management app. "
          "The user has these projects: $projectContext. "
          "When asked to modify tasks, execute the tool calls automatically. "
          "Use the available tools to perform actions directly.")
    ]);
  }

  Future<void> _startMentorChat() async {
    // If we have history but no chat session (e.g. app restart), we need to start one with history?
    // GenerativeModel.startChat(history: ...) takes existing Content.
    // However, our history is List<ChatMessage> (text), not List<Content>.
    // We should ideally convert _mentorMessages to history for startChat if we want continuity.
    // For now, let's just start a new session. The model won't see past turns unless we pass them.
    // Limitation: Loading history from DB shows in UI, but Model context is fresh unless we reconstruct.
    // IMPROVEMENT: Reconstruct history for Gemini.
    
    // Convert UI messages to Gemini Content for history
    final history = _mentorMessages.map((m) {
      return m.isUser ? Content.text(m.text) : Content.model([TextPart(m.text)]);
    }).toList();

    // Add System Prompt at the beginning? 
    // Gemini API `startChat` history usually implies conversation turns. System instructions are separate in new API but 
    // here we are using `gemini-3-pro-preview` which might expect system prompt as first message or valid system_instruction.
    // The `GenerativeModel` constructor has `systemInstruction`. We defined `_mentorModel` in `_initGemini` without it.
    // We should probably inject the context as the first "User" message or System Instruction if supported.
    // Current impl sends a first "User" message with context instructions? No, it sends `Content.text` which defaults to user role?
    // Actually `startChat` history elements should alternate or follow role rules.
    
    // Let's stick to current approach: Define context, then start chat.
    // If we have history, we should prepend context to the session or rely on system instruction.
    
    // To properly support persistence + context:
    // 1. We should ideally update `_mentorModel` definition to include `systemInstruction` with dynamic context? 
    //    But `GenerativeModel` is immutable/final usually.
    // 2. Or we send the context as a hidden first message.
    
    // Load Knowledge
    final knowledgeItems = await _dataService.getAllKnowledge();
    final knowledgeContext = knowledgeItems.isEmpty 
        ? "No specific user insights recorded yet."
        : knowledgeItems.map((k) => "- ${k.content}").join("\n");
    
    // Let's rebuild context.
    final projectContext = _dataService.projects.map((p) {
        final tasks = p.tasks.map((t) {
           final subtasks = t.subtasks.map((s) => "  - [${s.isCompleted ? 'x' : ' '}] ${s.title}").join("\n");
           return "- [${t.isCompleted ? 'x' : ' '}] ${t.title}${subtasks.isNotEmpty ? '\n$subtasks' : ''}";
        }).join("\n");
        return "Project: ${p.title}\nTasks:\n$tasks";
    }).join("\n\n");

    final systemPrompt = "You are a wise, empathetic mentor and productivity coach. "
          "You are NOT a task executor. Your goal is to help the user reflect, prioritize, and find clarity. "
          "You have access to a 'save_memory' tool. USE IT whenever the user shares a goal, preference, or important context that should be remembered.\n\n"
          "USER KNOWLEDGE (Memory):\n$knowledgeContext\n\n"
          "CURRENT WORK CONTEXT:\n\n$projectContext\n\n"
          "If the user asks to do something, guide them on WHY or HOW, but do not execute it directly. "
          "Keep responses concise, insightful, and encouraging.";

    if (_mentorChat == null) {
       // If history exists, we try to preserve it.
       // However, if we blindly pass history, we might duplicate the system prompt if we had one?
       // Let's just pass history if it exists, but we need to inject the NEW context (projects might have changed).
       // So maybe we just start fresh session but keeping UI history?
       // No, the model needs to know what was said.
       
       // Complex: Syncing DB history with Model State.
       // Simple fix: Start chat with history. Send Context as a hidden update? 
       // Or just set system instruction if possible.
       
       // For this task, let's keep it simple:
       // The `_startMentorChat` was used to INIT the chat.
       // If we already have messages, we want to include them.
       
       _mentorChat = _mentorModel.startChat(history: [
          Content.text(systemPrompt), // System context as first message
          ...history // Append previous conversation
       ]);
    }
  }

  void toggleMode() {
    _isMentorMode = !_isMentorMode;
    if (_isMentorMode && _mentorChat == null && Config.hasGeminiKey) {
      _startMentorChat();
    }
    notifyListeners();
  }



  Future<void> toggleRecording() async {
    final activeMessages = _isMentorMode ? _mentorMessages : _assistantMessages;

    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      if (_lastWords.isNotEmpty) {
        sendMessage(_lastWords);
      } else {
        if (_lastError.isNotEmpty) {
          activeMessages.add(ChatMessage(text: "Speech Error: $_lastError", isUser: false));
        } else {
          activeMessages.add(ChatMessage(text: "I didn't hear anything. Please try again.", isUser: false));
        }
        notifyListeners();
      }
    } else {
      print("[AssistantService] Requesting speech initialization...");
      bool available = false;
      _lastError = ''; // Clear previous errors
      try {
        available = await _speech.initialize(
          onStatus: (status) => print('[AssistantService] Speech status: $status'),
          onError: (error) {
            print('[AssistantService] Speech error: $error');
            _lastError = error.errorMsg;
            notifyListeners();
          },
        );
        print("[AssistantService] Speech initialized: $available");
      } catch (e) {
        print("[AssistantService] CRITICAL: Speech initialization threw error: $e");
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
        print("[AssistantService] Speech recognition denied or not available.");
        activeMessages.add(ChatMessage(text: "Microphone initialization failed or permission denied.", isUser: false));
        notifyListeners();
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    print("[VERIFY_FLOW] Service Receive: $text (Mode: ${_isMentorMode ? 'Mentor' : 'Assistant'})");

    final activeMessages = _isMentorMode ? _mentorMessages : _assistantMessages;
    final userMsg = ChatMessage(text: text, isUser: true);
    activeMessages.add(userMsg);
    
    // Save User Message
    await _dataService.saveChatMessage(userMsg, _isMentorMode ? 'mentor' : 'assistant');

    _isLoading = true;
    notifyListeners();

    try {
      if (!Config.hasGeminiKey) {
        await _handleMockMode(text, activeMessages);
        _isLoading = false;
        notifyListeners();
        return;
      }

      if (_isMentorMode) {
        await _handleMentorMessage(text, activeMessages);
      } else {
        await _handleAssistantMessage(text, activeMessages);
      }
    } catch (e) {
      final errorMsg = ChatMessage(text: "Error: $e", isUser: false);
      activeMessages.add(errorMsg);
      // We generally don't save ephemeral errors, but we can.
      debugPrint('AssistantService error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _handleMentorMessage(String text, List<ChatMessage> activeMessages) async {
    // Ensure chat is initialized (it might be null if we just loaded history from DB)
    if (_mentorChat == null) {
        await _startMentorChat();
    }
    
    // Mentor loop for tools (memory)
    var currentContent = Content.text(text);
    var iterations = 0;
    const maxIterations = 3; // Shorter loop for mentor
    
    while (iterations < maxIterations) {
       final response = await _mentorChat!.sendMessage(currentContent);
       
       if (response.functionCalls.isNotEmpty) {
           final functionResponses = <Content>[];
           for (var call in response.functionCalls) {
             try {
                final result = await _toolRegistry.executeTool(call.name, call.args);
                _executedActions.add(ProposedAction(
                  description: _toolRegistry.describeAction(call.name, call.args),
                  toolName: call.name,
                  toolArgs: call.args,
                ));
                notifyListeners();
                functionResponses.add(Content.functionResponse(call.name, result));
             } catch (e) {
                functionResponses.add(Content.functionResponse(call.name, {'result': 'error', 'message': e.toString()}));
             }
           }
           
           for (var i = 0; i < functionResponses.length; i++) {
            if (i == functionResponses.length - 1) {
              currentContent = functionResponses[i];
            } else {
              await _mentorChat!.sendMessage(functionResponses[i]);
            }
          }
          iterations++;
          continue;
       }
       
       final textResponse = response.text;
       if (textResponse != null && textResponse.isNotEmpty) {
          final aiMsg = ChatMessage(text: textResponse, isUser: false);
          activeMessages.add(aiMsg);
          await _dataService.saveChatMessage(aiMsg, 'mentor');
          
          if (_isVoiceEnabled) {
             _flutterTts.speak(textResponse);
          }
       }
       break;
    }
  }

  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    if (!_isVoiceEnabled) {
      _flutterTts.stop();
    }
    notifyListeners();
  }
  
  bool get isVoiceEnabled => _isVoiceEnabled;

  Future<void> _handleAssistantMessage(String text, List<ChatMessage> activeMessages) async {
      // Ensure chat is initialized
      if (_chat == null) _startNewChat();

    // Automatic tool execution loop (max 5 iterations to prevent infinite loops)
      var currentContent = Content.text(text);
      var iterations = 0;
      const maxIterations = 5;

      while (iterations < maxIterations) {
        final response = await _chat!.sendMessage(currentContent);
        
        // Check for function calls
        if (response.functionCalls.isNotEmpty) {
          print("[VERIFY_FLOW] Function calls detected: ${response.functionCalls.length}");
          
          // Execute all function calls and collect responses
          final functionResponses = <Content>[];
          for (var call in response.functionCalls) {
            try {
              print("[VERIFY_FLOW] Proposing tool: ${call.name} with args: ${call.args}");
              
              // Instead of executing, we propose the action
              _pendingActions.add(ProposedAction(
                description: _toolRegistry.describeAction(call.name, call.args),
                toolName: call.name,
                toolArgs: call.args,
              ));
              notifyListeners();
              
              // Tell the model we are waiting for user approval
              functionResponses.add(Content.functionResponse(
                call.name,
                {'result': 'pending', 'message': 'Action proposed to user. Waiting for approval.'},
              ));
              
              print("[VERIFY_FLOW] Tool proposed: ${call.name}");
            } catch (e) {
              print("[VERIFY_FLOW] Tool proposal error: $e");
              functionResponses.add(Content.functionResponse(
                call.name,
                {'result': 'error', 'message': e.toString()},
              ));
            }
          }
          
          // Send all function responses back to the model sequentially
          for (var i = 0; i < functionResponses.length; i++) {
            if (i == functionResponses.length - 1) {
              currentContent = functionResponses[i];
            } else {
              await _chat!.sendMessage(functionResponses[i]);
            }
          }
          iterations++;
          continue; // Loop to get next response
        }
        
        // No function calls - display final text response
        final textResponse = response.text;
        if (textResponse != null && textResponse.isNotEmpty) {
          final aiMsg = ChatMessage(text: textResponse, isUser: false);
          activeMessages.add(aiMsg);
          await _dataService.saveChatMessage(aiMsg, 'assistant');
        }
        break; // Exit loop
      }
      
      if (iterations >= maxIterations) {
        final warningMsg = ChatMessage(
          text: "Warning: Maximum tool execution iterations reached. Some operations may not have completed.",
          isUser: false
        );
        activeMessages.add(warningMsg);
        await _dataService.saveChatMessage(warningMsg, 'assistant');
      }
  }

  Future<void> _handleMockMode(String text, List<ChatMessage> activeMessages) async {
        await Future.delayed(const Duration(seconds: 1)); // Simulate latency
        
        if (_isMentorMode) {
             activeMessages.add(ChatMessage(text: "[Mock Mentor] That is a profound question. Have you considered the long-term implications?", isUser: false));
             return;
        }

        // Simple Mock Logic - Fixed regex to capture project names correctly
        // Try multiple patterns to capture project name
        // Pattern 1: "create ... (new) project 'name'" or "create ... (new) project \"name\""
        // This handles: "create a new project 'name'", "create new project 'name'", "create project 'name'"
        var projectMatch = RegExp("create\\s+(?:a\\s+)?(?:new\\s+)?project\\s+['\"]([^'\"]+)['\"]", caseSensitive: false).firstMatch(text);
        
        // Pattern 2: "create ... (new) project name" (without quotes, captures rest of string)
        // This handles: "create a new project name", "create new project name", "create project name"
        if (projectMatch == null) {
          projectMatch = RegExp("create\\s+(?:a\\s+)?(?:new\\s+)?project\\s+(.+)", caseSensitive: false).firstMatch(text);
        }
        
        if (projectMatch != null) {
          print("[VERIFY_FLOW] Regex Match: Success for Project");
          final title = projectMatch.group(1)?.trim() ?? 'New Project';
          print("[VERIFY_FLOW] Regex Captured Title: '$title'");
          
          // Mock Mode: Propose instead of execute
          _pendingActions.add(ProposedAction(
             description: "Create new project '$title'",
             toolName: 'add_project',
             toolArgs: {'title': title},
          ));
          notifyListeners();
          
          print("[VERIFY_FLOW] Mock Tool Proposed: add_project");
          activeMessages.add(ChatMessage(text: "I've proposed creating a new project '$title'. Please review it in the Action Log.", isUser: false));

        } else if (text.toLowerCase().contains("project")) {
             _pendingActions.add(ProposedAction(
               description: "Create new project 'New Project'",
               toolName: 'add_project',
               toolArgs: {'title': 'New Project'},
            ));
            notifyListeners();
            activeMessages.add(ChatMessage(text: "I've proposed creating a new project. Please review it.", isUser: false));

        } else if (text.toLowerCase().contains("task")) {
             _pendingActions.add(ProposedAction(
               description: "Add task 'New Task' to project",
               toolName: 'add_task',
               toolArgs: {'project_id': 'proj_1', 'title': 'New Task'},
            ));
            notifyListeners();
            activeMessages.add(ChatMessage(text: "I've proposed adding a task. Please review it.", isUser: false));

        } else {
          activeMessages.add(ChatMessage(text: "I am in Mock Mode. Ask me to 'add a project' or 'add a task' to see how I propose changes.", isUser: false));
        }
  }

  Future<void> acceptAction(ProposedAction action) async {
    try {
      await _toolRegistry.executeTool(action.toolName, action.toolArgs);
      _executedActions.add(action);
      _pendingActions.remove(action);
      notifyListeners();
      
      // We could add a system message here?
      // _assistantMessages.add(ChatMessage(text: "Action executed: ${action.description}", isUser: false));
    } catch (e) {
      debugPrint("Error executing action: $e");
    }
  }

  void declineAction(ProposedAction action) {
    _pendingActions.remove(action);
    notifyListeners();
  }
}

