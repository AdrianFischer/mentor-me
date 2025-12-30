import 'package:flutter/foundation.dart';
import '../models/ai_models.dart';
import 'ai_agent.dart';
import 'mcp_client_service.dart';

class McpAgentService extends AiAgent {
  final McpClientService _mcpClient;
  
  final List<ChatMessage> _messages = [];
  final List<ProposedAction> _pendingActions = [];
  final List<ProposedAction> _executedActions = [];
  
  bool _isLoading = false;
  bool _isThinkingMode = false;
  bool _isListening = false;
  bool _isVoiceEnabled = false;
  String _currentSpeech = '';
  String _draftMessage = '';

  McpAgentService(this._mcpClient);

  @override
  List<ChatMessage> get messages => _messages;
  
  @override
  List<ProposedAction> get pendingActions => _pendingActions;
  
  @override
  List<ProposedAction> get executedActions => _executedActions;
  
  @override
  bool get isLoading => _isLoading;
  
  @override
  bool get isThinkingMode => _isThinkingMode;
  
  @override
  bool get isListening => _isListening;
  
  @override
  bool get isVoiceEnabled => _isVoiceEnabled;
  
  @override
  String get currentSpeech => _currentSpeech;
  
  @override
  String get draftMessage => _draftMessage;

  @override
  Future<void> sendMessage(String text) async {
    _isLoading = true;
    _messages.add(ChatMessage(text: text, isUser: true));
    notifyListeners();
    
    try {
      // Placeholder: In a real implementation, we would send this to the MCP Agent
      // via a tool call or prompt.
      await Future.delayed(const Duration(seconds: 1));
      
      // Simulate response
      _messages.add(ChatMessage(text: "MCP Agent: I received '$text'. (Not fully implemented)", isUser: false));
    } catch (e) {
      _messages.add(ChatMessage(text: "Error: $e", isUser: false));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  @override
  Future<void> acceptAction(ProposedAction action) async {
    // Logic to tell external agent action was accepted
    action.isExecuted = true;
    _executedActions.add(action);
    notifyListeners();
  }

  @override
  void declineAction(ProposedAction action) {
    _pendingActions.remove(action);
    notifyListeners();
  }

  @override
  void toggleThinking() {
    _isThinkingMode = !_isThinkingMode;
    notifyListeners();
  }

  @override
  void toggleVoice() {
    _isVoiceEnabled = !_isVoiceEnabled;
    notifyListeners();
  }

  @override
  Future<void> toggleRecording() async {
    // No-op for now
    _isListening = !_isListening;
    if (_isListening) {
      _currentSpeech = "Listening (simulated)...";
    } else {
      _currentSpeech = "";
      if (_messages.isNotEmpty) {
        // simulate sending recorded text
        sendMessage("Simulated voice input");
      }
    }
    notifyListeners();
  }

  @override
  void setDraftMessage(String text) {
    _draftMessage = text;
  }

  @override
  Future<void> loadConversation(String conversationId) async {
    // Load logic
  }

  @override
  Future<String> createNewConversation(String title) async {
    return "mcp-conversation-id";
  }

  @override
  Future<void> clearHistory() async {
    _messages.clear();
    notifyListeners();
  }
}
