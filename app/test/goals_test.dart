import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';

class FakeStorageRepository implements StorageRepository {
  final List<Project> _projects = [];
  final StreamController<void> _controller = StreamController.broadcast();

  FakeStorageRepository({List<Project>? initialProjects}) {
    if (initialProjects != null) {
      _projects.addAll(initialProjects);
    }
  }

  @override
  Stream<void> get onDataChanged => _controller.stream;

  @override
  Future<void> init() async {}

  @override
  Future<List<Project>> getAllProjects() async => List.from(_projects);

  @override
  Future<void> saveProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index != -1) {
      _projects[index] = project;
    } else {
      _projects.add(project);
    }
    _controller.add(null);
  }

  @override
  Future<void> saveTask(Task task) async {
    if (task.projectId == null) return;
    final pIndex = _projects.indexWhere((p) => p.id == task.projectId);
    if (pIndex != -1) {
      final project = _projects[pIndex];
      final tIndex = project.tasks.indexWhere((t) => t.id == task.id);
      
      List<Task> newTasks = List.from(project.tasks);
      if (tIndex != -1) {
        newTasks[tIndex] = task;
      } else {
        newTasks.add(task);
      }
      _projects[pIndex] = project.copyWith(tasks: newTasks);
      _controller.add(null);
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      final newTasks = project.tasks.where((t) => t.id != taskId).toList();
      if (newTasks.length != project.tasks.length) {
        _projects[i] = project.copyWith(tasks: newTasks);
        _controller.add(null);
      }
    }
  }
  
  // Stubs for other methods
  @override
  Future<void> deleteProject(String projectId) async {}
  @override
  Future<void> saveConversation(Conversation conversation) async {}
  @override
  Future<List<Conversation>> getAllConversations() async => [];
  @override
  Future<void> deleteConversation(String conversationId) async {}
  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {}
  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async => [];
  @override
  Future<void> clearChatHistory(String mode, {String? conversationId}) async {}
  @override
  Future<void> saveKnowledge(Knowledge knowledge) async {}
  @override
  Future<List<Knowledge>> getAllKnowledge() async => [];
  @override
  Future<void> deleteKnowledge(String id) async {}
}

class FakeMarkdownPersistence implements MarkdownPersistenceService {
  @override
  bool get isEnabled => false;

  @override
  Future<void> saveTask(Task task, Project project) async {}
}

void main() {
  group('Goal Tracking Tests', () {
    late DataService dataService;
    late FakeStorageRepository repository;

    setUp(() async {
      repository = FakeStorageRepository();
      dataService = DataService(repository, FakeMarkdownPersistence());
      await dataService.initData();
    });

    test('Set and update Numeric Goal', () async {
      // 1. Create Project and Task
      final pid = await dataService.addProject("Test Project");
      final tid = (await dataService.addTask(pid, "Save Money"))!;

      // 2. Set Goal
      final goal = TaskGoal.numeric(target: 1000, unit: "\$");
      dataService.setTaskGoal(tid, goal);

      // Verify
      var task = dataService.projects.first.tasks.first;
      expect(task.goal, isNotNull);
      task.goal!.map(
        numeric: (n) {
          expect(n.target, 1000);
          expect(n.current, 0);
          expect(n.unit, "\$");
        },
        habit: (_) => fail("Should be numeric"),
      );

      // 3. Record Progress
      dataService.recordGoalProgress(tid, amount: 200, note: "First deposit");
      
      // Verify
      task = dataService.projects.first.tasks.first;
      task.goal!.map(
        numeric: (n) {
          expect(n.current, 200);
          expect(n.history.length, 1);
          expect(n.history.first.amount, 200);
          expect(n.history.first.note, "First deposit");
        },
        habit: (_) => fail("Should be numeric"),
      );

      // 4. Record more progress
      dataService.recordGoalProgress(tid, amount: 50);

      // Verify
      task = dataService.projects.first.tasks.first;
      task.goal!.map(
        numeric: (n) {
          expect(n.current, 250);
          expect(n.history.length, 2);
        },
        habit: (_) => fail("Should be numeric"),
      );
    });

    test('Set and update Habit Goal', () async {
      // 1. Create Project and Task
      final pid = await dataService.addProject("Habits");
      final tid = (await dataService.addTask(pid, "Exercise"))!;

      // 2. Set Goal
      final goal = TaskGoal.habit(targetFrequency: 0.8); // 80%
      dataService.setTaskGoal(tid, goal);

      // Verify
      var task = dataService.projects.first.tasks.first;
      task.goal!.map(
        numeric: (_) => fail("Should be habit"),
        habit: (h) {
          expect(h.targetFrequency, 0.8);
          expect(h.history, isEmpty);
        },
      );

      // 3. Record Success
      dataService.recordGoalProgress(tid, isSuccess: true, note: "Ran 5km");

      // Verify
      task = dataService.projects.first.tasks.first;
      task.goal!.map(
        numeric: (_) => fail("Should be habit"),
        habit: (h) {
          expect(h.history.length, 1);
          expect(h.history.first.isSuccess, true);
          expect(h.history.first.note, "Ran 5km");
        },
      );
    });
  });
}
