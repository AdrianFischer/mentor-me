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
import 'package:flutter_app/ui/assistant_screen.dart';
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
  Future<void> saveSubtask(Subtask subtask) async {} // DataService saves subtask via saveTask
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

void main() {
  testWidgets('Enter key adds new items in all columns', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(2000, 1000); // Desktop size
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    final fakeRepository = FakeStorageRepository(initialProjects: [

        Project(id: 'p1', title: 'Inbox'),
        Project(id: 'p2', title: 'Today'),
    ]);
    final mockAssistant = MockAssistantService();
    
    await tester.pumpWidget(ProviderScope(
      overrides: [
        storageRepositoryProvider.overrideWithValue(fakeRepository),
        assistantServiceProvider.overrideWith((ref) => mockAssistant),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp()
    ));
    await tester.pumpAndSettle();

    // 1. Projects Column
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); 
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); 
    await tester.pumpAndSettle();
    
    expect(find.text("Inbox"), findsOneWidget);
    
    // Press Enter to add new Project
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    final projectTextFields = find.descendant(
      of: find.byKey(const ValueKey('projects')),
      matching: find.byType(TextField),
    );
    expect(projectTextFields, findsNWidgets(3));
    
    final lastProjectField = projectTextFields.last;
    final textFieldWidget = tester.widget<TextField>(lastProjectField);
    expect(textFieldWidget.focusNode?.hasFocus, isTrue);
    
    await tester.enterText(lastProjectField, "New Project Test");
    await tester.pump();
    expect(find.text("New Project Test"), findsOneWidget);

    // 2. Tasks Column
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    final tasksColumn = find.text('Tasks');
    expect(tasksColumn, findsOneWidget);
    
    // Navigation right auto-creates a task if empty, so we don't need Enter
    
    final allEditableColumns = find.byType(EditableColumn);
    final taskColumnFinder = allEditableColumns.at(1);
    final taskTextFields = find.descendant(
      of: taskColumnFinder,
      matching: find.byType(TextField),
    );
    
    expect(taskTextFields, findsNWidgets(1));
    expect(tester.widget<TextField>(taskTextFields.last).focusNode?.hasFocus, isTrue);
    
    await tester.enterText(taskTextFields.last, "New Task Test");
    await tester.pump();
    expect(find.text("New Task Test"), findsOneWidget);
    
    // 3. Subtasks Column
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    expect(find.text('Subtasks'), findsOneWidget);
    
    // Navigation right auto-creates a subtask if empty, so we don't need Enter
    
    final subtaskColumnFinder = find.byType(EditableColumn).at(2); 
    
    final subtaskTextFields = find.descendant(
      of: subtaskColumnFinder,
      matching: find.byType(TextField),
    );
    expect(subtaskTextFields, findsNWidgets(1));

    expect(tester.widget<TextField>(subtaskTextFields.last).focusNode?.hasFocus, isTrue);
    
    await tester.enterText(subtaskTextFields.last, "New Subtask Test");
    await tester.pump();
    expect(find.text("New Subtask Test"), findsOneWidget);
  });
}
