import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/ui/widgets/editable_item_widget.dart'; // Import EditableItemWidget

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
  Future<void> saveSubtask(Subtask subtask) async {}
  @override
  Future<void> updateTitle(String id, String newTitle) async {}
  
  @override
  Future<void> setItemStatus(String id, bool isCompleted) async {
    for (var i = 0; i < _projects.length; i++) {
      final project = _projects[i];
      // Check tasks
      for (var j = 0; j < project.tasks.length; j++) {
        final task = project.tasks[j];
        if (task.id == id) {
          final newTask = task.copyWith(isCompleted: isCompleted);
          final newTasks = List<Task>.from(project.tasks);
          newTasks[j] = newTask;
          _projects[i] = project.copyWith(tasks: newTasks);
          _controller.add(null);
          return;
        }
      }
    }
  }

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

void main() {
  testWidgets('Checked state persistence test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1000);
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

    // 2. Select "Inbox" Project
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    // Create a task "Check Me"
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byType(TextField).last, "Check Me");
    await tester.pumpAndSettle();

    // 3. Find the checkbox
    // Find the task item widget first
    final taskItemFinder = find.byWidgetPredicate(
      (widget) => widget is EditableItemWidget && widget.item.text == "Check Me"
    );
    expect(taskItemFinder, findsOneWidget);

    final checkboxFinder = find.descendant(
      of: taskItemFinder,
      matching: find.byWidgetPredicate(
        (widget) => widget is Container && 
                    widget.decoration is BoxDecoration && 
                    (widget.decoration as BoxDecoration).shape == BoxShape.circle
      )
    );
    expect(checkboxFinder, findsOneWidget);
    
    final checkboxSize = tester.getSize(checkboxFinder);
    final checkboxCenter = tester.getCenter(checkboxFinder);

    // 4. Tap the checkbox to check it
    await tester.tapAt(checkboxCenter);
    await tester.pumpAndSettle();

    // Verify checked (Icon check appears)
    expect(find.byIcon(Icons.check), findsOneWidget);

    // 5. Navigate away to "Today" project
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    expect(find.text('Check Me'), findsNothing);

    // 6. Navigate back to "Inbox"
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    // 7. Verify "Check Me" is still checked
    expect(find.text('Check Me'), findsOneWidget);
    // Re-find because widget tree rebuilt
    final taskItemFinderBack = find.byWidgetPredicate(
      (widget) => widget is EditableItemWidget && widget.item.text == "Check Me"
    );
    final gestureDetectorsBack = find.descendant(
      of: taskItemFinderBack,
      matching: find.byType(GestureDetector)
    );
    final checkboxFinderBack = gestureDetectorsBack.last;
    
    // Check if Icon(Icons.check) is descendant of this item
    expect(
      find.descendant(of: taskItemFinderBack, matching: find.byIcon(Icons.check)),
      findsOneWidget
    );
  });
}
