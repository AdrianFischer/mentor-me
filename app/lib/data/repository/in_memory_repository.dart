import 'dart:async';
import '../../models/node.dart';
import '../../models/ai_models.dart';
import '../../services/file_persistence_service.dart';
import 'storage_repository.dart';

/// A non-persistent, in-memory implementation of StorageRepository.
/// Acts as a cache that delegates persistence to FilePersistenceService.
class InMemoryRepository implements StorageRepository {
  final FilePersistenceService _fileService;
  final List<Node> _nodes = [];
  final List<Conversation> _conversations = [];
  final List<ChatMessage> _chatHistory = [];
  final List<Knowledge> _knowledgeBase = [];
  final List<Memory> _memories = [];

  final _dataChangeController = StreamController<void>.broadcast();
  StreamSubscription? _watcherSubscription;

  InMemoryRepository(this._fileService);

  @override
  Stream<void> get onDataChanged => _dataChangeController.stream;

  @override
  Future<void> init() async {
    // 1. Initial Load
    try {
      final loadedNodes = await _fileService.loadAllNodes();
      _nodes.clear();
      _nodes.addAll(loadedNodes);
      print('InMemoryRepository loaded ${_nodes.length} nodes.');
    } catch (e) {
      print('InMemoryRepository init error: $e');
    }

    // 2. Start Watcher
    _watcherSubscription = _fileService.watchNodes().listen((updatedNodes) {
       _nodes.clear();
       _nodes.addAll(updatedNodes);

       // Notify app to redraw
       _dataChangeController.add(null);
    });
  }

  void dispose() {
    _watcherSubscription?.cancel();
    _dataChangeController.close();
  }

  // --- Nodes ---

  @override
  Future<List<Node>> getAllNodes() async {
    return List.unmodifiable(_nodes);
  }

  @override
  Future<void> saveNode(Node node) async {
    final index = _nodes.indexWhere((n) => n.id == node.id);
    if (index != -1) {
      _nodes[index] = node;
    } else {
      _nodes.add(node);
    }

    // Write-Through
    await _fileService.saveNode(node);
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    _nodes.removeWhere((n) => n.id == nodeId);
    await _fileService.deleteNode(nodeId);
  }

  // --- Conversations ---

  @override
  Future<List<Conversation>> getAllConversations() async {
    return List.unmodifiable(_conversations);
  }

  @override
  Future<void> saveConversation(Conversation conversation) async {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }
  }

  @override
  Future<void> deleteConversation(String conversationId) async {
    _conversations.removeWhere((c) => c.id == conversationId);
    _chatHistory.removeWhere((m) => m.conversationId == conversationId);
  }

  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {
    _chatHistory.add(message);
  }

  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      return _chatHistory.where((m) => m.conversationId == conversationId).toList();
    }
    return _chatHistory.toList();
  }

  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {
    if (conversationId != null) {
      _chatHistory.removeWhere((m) => m.conversationId == conversationId);
    } else {
      _chatHistory.clear();
    }
  }

  @override
  Future<List<Knowledge>> getAllKnowledge() async {
    return List.unmodifiable(_knowledgeBase);
  }

  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {
     _knowledgeBase.add(knowledge);
  }

  @override
  Future<void> deleteKnowledge(String id) async {
     _knowledgeBase.removeWhere((k) => k.id == id);
  }

  @override
  Future<void> saveMemory(Memory memory) async {
    _memories.add(memory);
  }

  @override
  Future<List<Memory>> getAllMemories() async {
    return List.unmodifiable(_memories);
  }

  @override
  Future<void> deleteMemory(String id) async {
    _memories.removeWhere((m) => m.id == id);
  }
}
