import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/models.dart';
import '../models/ai_models.dart';
import '../data/repository/storage_repository.dart';

class ConversationService extends ChangeNotifier {
  final StorageRepository _repository;
  List<Conversation> _conversations = [];
  bool _isInitialized = false;
  StreamSubscription? _dataSubscription;

  ConversationService(this._repository);

  List<Conversation> get conversations => _conversations;

  Future<void> initData() async {
    if (_isInitialized) return;
    _isInitialized = true;
    
    _dataSubscription = _repository.onDataChanged.listen((_) {
      print("Data change detected. Reloading...");
      _reloadConversations();
    });
    
    await _reloadConversations();
  }

  Future<void> _reloadConversations() async {
    final list = await _repository.getAllConversations();
    _conversations = List.from(list);
    notifyListeners();
  }

  String createConversation(String title) {
    final conversation = Conversation(title: title);
    _conversations = List<Conversation>.from(_conversations)..insert(0, conversation);
    notifyListeners();
    _repository.saveConversation(conversation);
    return conversation.id;
  }

  void updateConversationTitle(String id, String title) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _conversations[index].copyWith(title: title, lastModified: DateTime.now());
      _conversations = List<Conversation>.from(_conversations)..[index] = updated;
      notifyListeners();
      _repository.saveConversation(updated);
    }
  }

  void updateConversationNotes(String id, String notes) {
    final index = _conversations.indexWhere((c) => c.id == id);
    if (index != -1) {
      final updated = _conversations[index].copyWith(notes: notes, lastModified: DateTime.now());
      _conversations = List<Conversation>.from(_conversations)..[index] = updated;
      notifyListeners();
      _repository.saveConversation(updated);
    }
  }

  void deleteConversation(String id) {
    _conversations = List<Conversation>.from(_conversations)..removeWhere((c) => c.id == id);
    notifyListeners();
    _repository.deleteConversation(id);
  }

  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    await _repository.saveChatMessage(message, mode);
  }

  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    return _repository.getChatHistory(mode, conversationId: conversationId);
  }

  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    await _repository.clearChatHistory(mode, conversationId: conversationId);
  }

  void clear() {
    _conversations = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _dataSubscription?.cancel();
    super.dispose();
  }
}
