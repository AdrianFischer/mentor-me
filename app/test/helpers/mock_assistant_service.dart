import 'package:flutter/foundation.dart';
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/models/ai_models.dart';

class MockAssistantService extends ChangeNotifier implements AssistantService {
  @override
  List<ChatMessage> get messages => [];
  @override
  List<ProposedAction> get pendingActions => [];
  @override
  List<ProposedAction> get executedActions => [];
  @override
  bool get isListening => false;
  @override
  bool get isLoading => false;
  @override
  bool get isThinkingMode => false;
  @override
  String get currentSpeech => '';
  
  @override
  String? get currentConversationId => 'mock_conv_id';
  
  String _draftMessage = '';
  @override
  String get draftMessage => _draftMessage;
  
  @override
  void setDraftMessage(String text) {
    _draftMessage = text;
    notifyListeners();
  }

  @override
  Future<String> createNewConversation(String title) async => 'new_conv_id';

  @override
  Future<void> loadConversation(String conversationId) async {}

  @override
  Future<void> sendMessage(String text) async {}
  @override
  Future<void> acceptAction(ProposedAction action) async {}
  @override
  void declineAction(ProposedAction action) {}
  @override
  Future<void> toggleRecording() async {}
  @override
  void toggleThinking() {}
  @override
  void toggleVoice() {}
  @override
  Future<void> clearHistory() async {}
  @override
  bool get isVoiceEnabled => false;
}
