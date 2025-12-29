import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';

class FakeStorageRepository implements StorageRepository {
  List<Project> _projects = [];
  final _controller = StreamController<void>.broadcast();
  
  @override
  List<Project> getProjects() => _projects;

  @override
  Future<void> saveProject(Project project) async {
    _projects.add(project);
    _controller.add(null);
  }

  @override
  Future<void> saveTask(Task task) async {}

  @override
  Future<void> saveSubtask(Subtask subtask) async {}

  @override
  Future<void> updateTitle(String id, String newTitle) async {}

  @override
  Future<void> setItemStatus(String id, bool isCompleted) async {}

  @override
  Future<void> deleteItem(String id) async {}

  @override
  Future<void> reorderProjects(int oldIndex, int newIndex) async {}

  @override
  Future<void> reorderTasks(String projectId, int oldIndex, int newIndex) async {}

  @override
  Future<void> reorderSubtasks(String taskId, int oldIndex, int newIndex) async {}
  
  @override
  Future<void> deleteProject(String projectId) async {}
  
  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {}
  
  @override
  Future<List<ChatMessage>> getChatHistory(String mode) async => [];
  
  @override
  Future<void> clearChatHistory(String mode) async {}
  
  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {}
  
  @override
  Future<List<Knowledge>> getAllKnowledge() async => [];
  
  @override
  Future<void> deleteKnowledge(String id) async {}

  @override
  Future<void> deleteTask(String taskId) async {}

  @override
  Future<List<Project>> getAllProjects() async => _projects;

  @override
  Future<void> init() async {}

  @override
  Stream<void> get onDataChanged => _controller.stream;
}

class FakeMarkdownPersistence extends MarkdownPersistenceService {
  FakeMarkdownPersistence() : super(baseDir: null); // Pass null to disable
  
  @override
  bool get isEnabled => false;
}

void main() {
  group('DataService Initialization', () {
    late DataService dataService;

    setUp(() {
      dataService = DataService(FakeStorageRepository(), FakeMarkdownPersistence());
    });

    test('DataService initializes with empty projects', () {
      expect(dataService.projects, isEmpty);
    });
  });
}
