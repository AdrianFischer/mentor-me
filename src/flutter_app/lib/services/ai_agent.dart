import 'package:flutter/foundation.dart';
import '../models/ai_models.dart';

abstract class AiAgent extends ChangeNotifier {
  List<ChatMessage> get messages;
  List<ProposedAction> get pendingActions;
  List<ProposedAction> get executedActions;
  
  bool get isLoading;
  bool get isThinkingMode;
  bool get isListening;
  bool get isVoiceEnabled;
  String get currentSpeech;
  String get draftMessage;

  Future<void> sendMessage(String text);
  Future<void> acceptAction(ProposedAction action);
  void declineAction(ProposedAction action);
  
  void toggleThinking();
  void toggleVoice();
  Future<void> toggleRecording();
  
  void setDraftMessage(String text);
  
  Future<void> loadConversation(String conversationId);
  Future<String> createNewConversation(String title);
  Future<void> clearHistory();
}
