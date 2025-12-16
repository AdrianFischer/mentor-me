import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:speech_to_text/speech_to_text.dart';
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
  String _apiKey = '';
  
  // Speech
  final SpeechToText _speech = SpeechToText();
  bool _isListening = false;
  String _lastWords = '';
  String _lastError = '';

  // State
  final List<ChatMessage> _messages = [];
  final List<ProposedAction> _pendingActions = []; // Kept for backward compat, but effectively unused
  final List<ProposedAction> _executedActions = []; // New: Track history
  bool _isLoading = false;

  AssistantService(this._dataService, this._toolRegistry) {
    _initGemini();
    // _initSpeech(); // Delay initialization to avoid crash on startup
  }

  List<ChatMessage> get messages => _messages;
  List<ProposedAction> get pendingActions => _pendingActions;
  List<ProposedAction> get executedActions => _executedActions;
  bool get isListening => _isListening;
  bool get isLoading => _isLoading;
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
    
    // Only start chat if we have a key, otherwise we'll mock it
    if (Config.hasGeminiKey) {
       _startNewChat();
    }
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


  Future<void> toggleRecording() async {
    if (_isListening) {
      await _speech.stop();
      _isListening = false;
      notifyListeners();
      if (_lastWords.isNotEmpty) {
        sendMessage(_lastWords);
      } else {
        if (_lastError.isNotEmpty) {
          _messages.add(ChatMessage(text: "Speech Error: $_lastError", isUser: false));
        } else {
          _messages.add(ChatMessage(text: "I didn't hear anything. Please try again.", isUser: false));
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
        _messages.add(ChatMessage(text: "Microphone initialization failed or permission denied.", isUser: false));
        notifyListeners();
      }
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    print("[VERIFY_FLOW] Service Receive: $text"); // Debug print

    _messages.add(ChatMessage(text: text, isUser: true));
    _isLoading = true;
    notifyListeners();

    try {
      // Mock Mode Check
      if (!Config.hasGeminiKey) {
        await Future.delayed(const Duration(seconds: 1)); // Simulate latency
        
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
          // In mock mode, execute directly
          try {
            await _toolRegistry.executeTool('add_project', {'title': title});
            
            _executedActions.add(ProposedAction(
               description: "Create new project '$title'",
               toolName: 'add_project',
               toolArgs: {'title': title},
            ));
            
            print("[VERIFY_FLOW] Mock Tool Executed: add_project");
            _messages.add(ChatMessage(text: "I've created a new project '$title'.", isUser: false));
          } catch (e) {
            _messages.add(ChatMessage(text: "Error creating project: $e", isUser: false));
          }
        } else if (text.toLowerCase().contains("project")) {
          try {
            await _toolRegistry.executeTool('add_project', {'title': 'New Project'});
            
            _executedActions.add(ProposedAction(
               description: "Create new project 'New Project'",
               toolName: 'add_project',
               toolArgs: {'title': 'New Project'},
            ));
            
            print("[VERIFY_FLOW] Mock Tool Executed: add_project");
            _messages.add(ChatMessage(text: "I've created a new project 'New Project'.", isUser: false));
          } catch (e) {
            _messages.add(ChatMessage(text: "Error creating project: $e", isUser: false));
          }
        } else if (text.toLowerCase().contains("task")) {
          try {
            await _toolRegistry.executeTool('add_task', {'project_id': 'proj_1', 'title': 'New Task'});
            
            _executedActions.add(ProposedAction(
               description: "Add task 'New Task' to project",
               toolName: 'add_task',
               toolArgs: {'project_id': 'proj_1', 'title': 'New Task'},
            ));
            
            print("[VERIFY_FLOW] Mock Tool Executed: add_task");
            _messages.add(ChatMessage(text: "I've added a task 'New Task'.", isUser: false));
          } catch (e) {
            _messages.add(ChatMessage(text: "Error adding task: $e", isUser: false));
          }
        } else {
          _messages.add(ChatMessage(text: "I am in Mock Mode. Ask me to 'add a project' or 'add a task' to see how I execute changes.", isUser: false));
        }
        
        _isLoading = false;
        notifyListeners();
        return;
      }

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
              print("[VERIFY_FLOW] Executing tool: ${call.name} with args: ${call.args}");
              final result = await _toolRegistry.executeTool(call.name, call.args);
              
              // Log to history
              _executedActions.add(ProposedAction(
                description: _toolRegistry.describeAction(call.name, call.args),
                toolName: call.name,
                toolArgs: call.args,
              ));
              notifyListeners();
              
              // Create function response using positional arguments
              functionResponses.add(Content.functionResponse(
                call.name,
                result,
              ));
              
              print("[VERIFY_FLOW] Tool executed successfully: ${call.name}");
            } catch (e) {
              print("[VERIFY_FLOW] Tool execution error: $e");
              // Send error response back to model
              functionResponses.add(Content.functionResponse(
                call.name,
                {'result': 'error', 'message': e.toString()},
              ));
            }
          }
          
          // Send all function responses back to the model sequentially
          // The chat session maintains conversation context
          for (var i = 0; i < functionResponses.length; i++) {
            if (i == functionResponses.length - 1) {
              // Last response - use it for the next iteration
              currentContent = functionResponses[i];
            } else {
              // Send intermediate responses
              await _chat!.sendMessage(functionResponses[i]);
            }
          }
          iterations++;
          continue; // Loop to get next response
        }
        
        // No function calls - display final text response
        final textResponse = response.text;
        if (textResponse != null && textResponse.isNotEmpty) {
          _messages.add(ChatMessage(text: textResponse, isUser: false));
        }
        break; // Exit loop
      }
      
      if (iterations >= maxIterations) {
        _messages.add(ChatMessage(
          text: "Warning: Maximum tool execution iterations reached. Some operations may not have completed.",
          isUser: false
        ));
      }
    } catch (e) {
      _messages.add(ChatMessage(text: "Error: $e", isUser: false));
      debugPrint('AssistantService error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> acceptAction(ProposedAction action) async {
    await _toolRegistry.executeTool(action.toolName, action.toolArgs);
    _pendingActions.remove(action);
    notifyListeners();
    
    // Optionally send tool result back to Gemini so it knows it's done
    // _chat!.sendMessage(Content.functionResponse(
    //   action.toolName, 
    //   {'result': 'success'}
    // ));
  }

  void declineAction(ProposedAction action) {
    _pendingActions.remove(action);
    notifyListeners();
  }
}

