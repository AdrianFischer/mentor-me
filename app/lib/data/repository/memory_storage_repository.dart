import 'dart:async';
import '../../models/node.dart';
import '../../models/ai_models.dart';
import 'storage_repository.dart';

class MemoryStorageRepository implements StorageRepository {
  final List<Node> _nodes = [];
  final List<Conversation> _conversations = [];
  final Map<String, List<ChatMessage>> _chatHistories = {};
  final List<Knowledge> _knowledgeBase = [];
  final List<Memory> _memories = [];
  final StreamController<void> _dataChangeController = StreamController<void>.broadcast();

  @override
  Stream<void> get onDataChanged => _dataChangeController.stream;

  @override
  Future<void> init() async {}

  @override
  Future<List<Node>> getAllNodes() async {
    return List.unmodifiable(_nodes);
  }

  @override
  Future<void> saveNode(Node node) async {
    final index = _nodes.indexWhere((n) => n.id == node.id);
    if (index >= 0) {
      _nodes[index] = node;
    } else {
      _nodes.add(node);
    }
    _dataChangeController.add(null);
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    _nodes.removeWhere((n) => n.id == nodeId);
    _dataChangeController.add(null);
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index >= 0) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }
  }

  @override
  Future<List<Conversation>> getAllConversations() async {
    return List.unmodifiable(_conversations);
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
  }

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    final key = message.conversationId ?? mode;
    _chatHistories.putIfAbsent(key, () => []).add(message);
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    final key = conversationId ?? mode;
    return List.unmodifiable(_chatHistories[key] ?? []);
  }

  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    final key = conversationId ?? mode;
    _chatHistories[key] = [];
  }

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
    final index = _knowledgeBase.indexWhere((k) => k.id == knowledge.id);
    if (index >= 0) {
      _knowledgeBase[index] = knowledge;
    } else {
      _knowledgeBase.add(knowledge);
    }
  }

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    return List.unmodifiable(_knowledgeBase);
  }

  @override
  Future<void> deleteKnowledge(String id) async {
    _knowledgeBase.removeWhere((k) => k.id == id);
  }

  @override
  Future<void> saveMemory(Memory memory) async {
    final index = _memories.indexWhere((m) => m.id == memory.id);
    if (index >= 0) {
      _memories[index] = memory;
    } else {
      _memories.add(memory);
    }
    _dataChangeController.add(null);
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    return List.unmodifiable(_memories);
  }

  @override
  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
    _dataChangeController.add(null);
  }
}
