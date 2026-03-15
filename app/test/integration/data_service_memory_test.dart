import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/ai_models.dart';

void main() {
  group('NodeService with SimpleRepository', () {
    late NodeService nodeService;

    test('addChild should create a root node', () async {
      final repository = _SimpleRepository();
      nodeService = NodeService(repository);
      await nodeService.initData();

      final id = await nodeService.addChild(null, 'Test Project');

      expect(nodeService.rootNodes.length, 1);
      expect(nodeService.rootNodes.first.id, id);
      expect(nodeService.rootNodes.first.title, 'Test Project');
    });

    test('addChild should create a child node under a root', () async {
      final repository = _SimpleRepository();
      nodeService = NodeService(repository);
      await nodeService.initData();

      final projectId = await nodeService.addChild(null, 'Project 1');
      await nodeService.addChild(projectId, 'Task 1');

      final project = nodeService.rootNodes.first;
      expect(project.children.length, 1);
      expect(project.children.first.title, 'Task 1');
    });

    test('addChild should persist the node', () async {
      final repository = _SimpleRepository();
      nodeService = NodeService(repository);
      await nodeService.initData();

      await nodeService.addChild(null, 'Persistent Project');

      final nodes = await repository.getAllNodes();
      expect(nodes.length, 1);
      expect(nodes.first.title, 'Persistent Project');
    });
  });
}

/// Minimal in-memory StorageRepository for testing.
class _SimpleRepository implements StorageRepository {
  final List<Node> _nodes = [];
  final _controller = StreamController<void>.broadcast();

  @override
  Future<void> init() async {}

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
  }

  @override
  Future<void> deleteNode(String nodeId) async {
    _nodes.removeWhere((n) => n.id == nodeId);
  }

  @override
  Future<void> saveConversation(Conversation c) async {}
  @override
  Future<List<Conversation>> getAllConversations() async => [];
  @override
  Future<void> deleteConversation(String id) async {}
  @override
  Future<void> saveChatMessage(ChatMessage m, String mode) async {}
  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async => [];
  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {}
  @override
  Future<void> saveKnowledge(Knowledge k) async {}
  @override
  Future<List<Knowledge>> getAllKnowledge() async => [];
  @override
  Future<void> deleteKnowledge(String id) async {}
  @override
  Future<void> saveMemory(Memory m) async {}
  @override
  Future<List<Memory>> getAllMemories() async => [];
  @override
  Future<void> deleteMemory(String id) async {}
  @override
  Stream<void> get onDataChanged => _controller.stream;
}
