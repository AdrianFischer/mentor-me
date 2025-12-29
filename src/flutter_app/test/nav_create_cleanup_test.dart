import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}


class FakeStorageRepository implements StorageRepository {
  List<Project> _projects;
  final _controller = StreamController<void>.broadcast();
  
  FakeStorageRepository({List<Project>? initialProjects}) 
      : _projects = initialProjects ?? [];

  @override
  List<Project> getProjects() => _projects;

  @override
  Future<void> saveProject(Project project) async {
    final index = _projects.indexWhere((p) => p.id == project.id);
    if (index >= 0) {
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
      
      List<Task> newTasks;
      if (tIndex != -1) {
        newTasks = List<Task>.from(project.tasks);
        newTasks[tIndex] = task;
      } else {
        newTasks = List<Task>.from(project.tasks)..add(task);
      }
      _projects[pIndex] = project.copyWith(tasks: newTasks);
      _controller.add(null);
    }
  }

  @override
  Future<void> saveSubtask(Subtask subtask) async {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      // Find task that contains this subtask or if new, we don't know parent from Subtask object alone 
      // EXCEPT in this app subtask doesn't store taskId. 
      // But DataService.addSubtask calls repository.saveTask(newTask), NOT saveSubtask.
      // Wait, let's check DataService.
    }
  }

  @override
  Future<void> updateTitle(String id, String newTitle) async {
     // ... (can implement if needed, but test doesn't seem to rely on persistence of title updates via repo directly, but DataService does)
  }

  @override
  Future<void> setItemStatus(String id, bool isCompleted) async {}

  @override
  Future<void> deleteItem(String id) async {
    // Try delete project
    int pIndex = _projects.indexWhere((p) => p.id == id);
    if (pIndex != -1) {
      _projects.removeAt(pIndex);
      _controller.add(null);
      return;
    }
    
    // Try delete task
    for (var i = 0; i < _projects.length; i++) {
      var project = _projects[i];
      int tIndex = project.tasks.indexWhere((t) => t.id == id);
      if (tIndex != -1) {
        var newTasks = List<Task>.from(project.tasks)..removeAt(tIndex);
        _projects[i] = project.copyWith(tasks: newTasks);
        _controller.add(null);
        return;
      }
      
      // Try delete subtask
      for (var j = 0; j < project.tasks.length; j++) {
        var task = project.tasks[j];
        int sIndex = task.subtasks.indexWhere((s) => s.id == id);
        if (sIndex != -1) {
           var newSubtasks = List<Subtask>.from(task.subtasks)..removeAt(sIndex);
           var newTask = task.copyWith(subtasks: newSubtasks);
           var newTasks = List<Task>.from(project.tasks);
           newTasks[j] = newTask;
           _projects[i] = project.copyWith(tasks: newTasks);
           _controller.add(null);
           return;
        }
      }
    }
  }
  @override
  Future<void> reorderProjects(int oldIndex, int newIndex) async {}
  @override
  Future<void> reorderTasks(String projectId, int oldIndex, int newIndex) async {}
  @override
  Future<void> reorderSubtasks(String taskId, int oldIndex, int newIndex) async {}
  @override
  Future<void> deleteProject(String projectId) async {
    _projects.removeWhere((p) => p.id == projectId);
    _controller.add(null);
  }
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

void main() {
  testWidgets('Navigation Right Auto-Creates Item', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepository = FakeStorageRepository(initialProjects: [
        Project(id: 'p1', title: 'Inbox'),
        Project(id: 'p2', title: 'Today'),
    ]);
    
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(fakeRepository),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp()
    ));
    await tester.pumpAndSettle();

    // 1. Create a new project (empty)
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    // 2. Navigate Right -> Should create a Task
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    // Check Tasks column
    expect(find.text('Tasks'), findsOneWidget);
    
    // Should have 1 TextField (the auto-created one)
    final allEditableColumns = find.byType(EditableColumn);
    final taskColumnFinder = allEditableColumns.at(1);
    final taskTextFields = find.descendant(
      of: taskColumnFinder,
      matching: find.byType(TextField),
    );
    expect(taskTextFields, findsOneWidget);
    
    // Verify focus
    expect(tester.widget<TextField>(taskTextFields.last).focusNode?.hasFocus, isTrue);
    
    // 3. Navigate Right -> Should create a Subtask
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    expect(find.text('Subtasks'), findsOneWidget);
    
    final subtaskColumnFinder = allEditableColumns.at(2);
    final subtaskTextFields = find.descendant(
      of: subtaskColumnFinder,
      matching: find.byType(TextField),
    );
    expect(subtaskTextFields, findsOneWidget);
    
    // Verify focus
    expect(tester.widget<TextField>(subtaskTextFields.last).focusNode?.hasFocus, isTrue);

  });

  testWidgets('Cleanup Empty Items on Navigation', (WidgetTester tester) async {
    final fakeRepository = FakeStorageRepository();
    
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(fakeRepository),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp()
    ));
    await tester.pumpAndSettle();

    // 1. Create a new project
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    // We have an empty project selected.
    // 2. Create another new project
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    final projectTextFields = find.descendant(
      of: find.byKey(const ValueKey('projects')),
      matching: find.byType(TextField),
    );
    
    int countBeforeMove = projectTextFields.evaluate().length;
    
    // 3. Move Up. 
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    
    int countAfterMove = projectTextFields.evaluate().length;
    
    // We expect count to decrease by 1.
    expect(countAfterMove, countBeforeMove - 1);
  });
}
