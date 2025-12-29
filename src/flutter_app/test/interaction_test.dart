import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/widgets/editable_item_widget.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/ui/assistant_screen.dart'; // assistantServiceProvider
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:mocktail/mocktail.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}

class MockAssistantService extends ChangeNotifier implements AssistantService {
  @override
  List<ChatMessage> get messages => [];
  @override
  List<ProposedAction> get pendingActions => [];
  @override
  List<ProposedAction> get executedActions => [];
  @override
  bool get isListening => false;
  @override
  bool get isLoading => false;
  @override
  bool get isThinkingMode => false;
  @override
  String get currentSpeech => '';
  
  // Stubs for other methods
  @override
  Future<void> sendMessage(String text) async {}
  @override
  Future<void> acceptAction(ProposedAction action) async {}
  @override
  void declineAction(ProposedAction action) {}
  @override
  Future<void> toggleRecording() async {}
  @override
  void toggleThinking() {}
  @override
  void toggleVoice() {}
  @override
  Future<void> clearHistory() async {}
  @override
  bool get isVoiceEnabled => false;
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
  testWidgets('Navigation, Typing, and Checkbox Toggle Test', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepository = FakeStorageRepository(initialProjects: [
        Project(id: 'p1', title: 'Inbox'),
    ]);
    final mockAssistant = MockAssistantService();
    
    // 1. Build App
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(fakeRepository),
        assistantServiceProvider.overrideWith((ref) => mockAssistant),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp()
    ));
    await tester.pumpAndSettle();
    
    // Navigate to Inbox
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Assistant
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Inbox
    await tester.pumpAndSettle();
    
    expect(find.text("Inbox"), findsOneWidget);
    
    // Navigate Right to Tasks
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    expect(find.text("Tasks"), findsOneWidget);
    
    // Create a task
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    await tester.enterText(find.byType(TextField).last, "My New Task");
    await tester.pumpAndSettle();
    
    expect(find.text("My New Task"), findsOneWidget);
    
    // Toggle checkbox
    // Find the task item widget first
    final taskItemFinder = find.byWidgetPredicate(
      (widget) => widget is EditableItemWidget && widget.item.text == "My New Task"
    );
    expect(taskItemFinder, findsOneWidget);

    // Find the checkbox gesture detector within it. 
    // The main widget has a GestureDetector, and the checkbox has one.
    // The checkbox is inside the Row.
    final gestureDetectors = find.descendant(
      of: taskItemFinder,
      matching: find.byType(GestureDetector)
    );
    
    // We expect at least 2: 1 for item tap, 1 for checkbox.
    // The structure is EditableItemWidget -> Container -> GestureDetector(main) -> ... -> GestureDetector(checkbox)
    // So both are descendants.
    // We want the inner one (checkbox).
    final checkbox = gestureDetectors.last; 
    
    await tester.tap(checkbox);
    await tester.pumpAndSettle();
    
    // Verify checked (Icon check appears)
    expect(find.byIcon(Icons.check), findsOneWidget);
  });
}