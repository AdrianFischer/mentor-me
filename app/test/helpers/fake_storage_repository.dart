import 'dart:async';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/models/ai_models.dart';

class FakeStorageRepository implements StorageRepository {
  final List<Node> _nodes;
  final List<Conversation> _conversations = [];
  final List<ChatMessage> _messages = [];
  final List<Knowledge> _knowledge = [];
  final List<Memory> _memories = [];
  final _controller = StreamController<void>.broadcast();

  FakeStorageRepository({List<Node>? initialNodes})
      : _nodes = initialNodes ?? [];

  List<Node> getNodes() => _nodes;

  @override
  Future<List<Node>> getAllNodes() async => _nodes;

  @override
  Future<void> saveNode(Node node) async {
    final index = _nodes.indexWhere((n) => n.id == node.id);
    if (index >= 0) {
      _nodes[index] = node;
    } else {
      _nodes.add(node);
    }
    _controller.add(null);
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    _nodes.removeWhere((n) => n.id == nodeId);
    _controller.add(null);
  }

  // --- Chat History ---

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
    return _conversations;
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    _messages.removeWhere((m) => m.conversationId == conversationId);
  }

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    _messages.add(message);
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      return _messages.where((m) => m.conversationId == conversationId).toList();
    }
    return _messages;
  }

  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      _messages.removeWhere((m) => m.conversationId == conversationId);
    } else {
      _messages.clear();
    }
  }

  // --- Knowledge ---

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
    final index = _knowledge.indexWhere((k) => k.id == knowledge.id);
    if (index >= 0) {
      _knowledge[index] = knowledge;
    } else {
      _knowledge.add(knowledge);
    }
  }

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    return _knowledge;
  }

  @override
  Future<void> deleteKnowledge(String id) async {
    _knowledge.removeWhere((k) => k.id == id);
  }

  @override
  Future<void> saveMemory(Memory memory) async {
    final index = _memories.indexWhere((m) => m.id == memory.id);
    if (index >= 0) {
      _memories[index] = memory;
    } else {
      _memories.add(memory);
    }
    _controller.add(null);
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    return _memories;
  }

  @override
  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
    _controller.add(null);
  }

  @override
  Future<void> init() async {}

  @override
  Stream<void> get onDataChanged => _controller.stream;
}
