import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';
import 'package:flutter_app/ui/actions/selection_actions.dart';
import 'package:flutter_app/providers/selection_provider.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/ui/assistant_screen.dart';
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:flutter_app/providers/ai_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'helpers/fake_storage_repository.dart';
import 'helpers/mock_assistant_service.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}

void main() {
  testWidgets('Cmd+N adds new items in all columns', (WidgetTester tester) async {
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
        internalAgentProvider.overrideWith((ref) => mockAssistant),
        mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
      ],
      child: const MyApp()
    ));
    await tester.pumpAndSettle();

    final container = ProviderScope.containerOf(tester.element(find.byType(MyApp)));

    // Ensure root focus
    Focus.of(tester.element(find.byKey(const ValueKey('rootFocus')))).requestFocus();
    await tester.pumpAndSettle();

    // 1. Projects Column
    await tester.tap(find.text("Inbox"));
    await tester.pumpAndSettle();
    
    expect(find.text("Inbox"), findsOneWidget);
    
    // Press Cmd+N to add new Project
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    
    for (int i=0; i<5; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    final projectTextFields = find.descendant(
      of: find.byKey(const ValueKey('projects')),
      matching: find.byType(TextField),
    );
    expect(projectTextFields, findsNWidgets(2));
    
    final lastProjectField = projectTextFields.first; // Title is first
    final textFieldWidget = tester.widget<TextField>(lastProjectField);
    expect(textFieldWidget.focusNode?.hasFocus, isTrue);
    
    await tester.enterText(lastProjectField, "New Project Test");
    await tester.pump();
    expect(find.text("New Project Test"), findsOneWidget);

    // Exit Edit Mode
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // 2. Tasks Column
    // Navigate Right to Tasks (Auto-creates task if empty)
    container.read(selectionProvider.notifier).changeColumn(1);
    for (int i=0; i<10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    final tasksColumn = find.text('Tasks');
    expect(tasksColumn, findsOneWidget);
    
    final taskColumnFinder = find.ancestor(of: find.text('Tasks'), matching: find.byType(EditableColumn));
    final taskTextFields = find.descendant(
      of: taskColumnFinder,
      matching: find.byType(TextField),
    );
    
    expect(taskTextFields, findsNWidgets(2));
    expect(tester.widget<TextField>(taskTextFields.first).focusNode?.hasFocus, isTrue);
    
    await tester.enterText(taskTextFields.first, "New Task Test");
    await tester.pump();
    expect(find.text("New Task Test"), findsOneWidget);
    
    // Explicitly select the task to ensure Subtasks column will show
    final dataService = container.read(dataServiceProvider);
    
    // Wait for data to sync
    Task? newTask;
    for (int i=0; i<10; i++) {
      try {
        // The last project added is our target
        final p = dataService.projects.last;
        newTask = p.tasks.firstWhere((t) => t.title == "New Task Test");
        if (newTask != null) break;
      } catch (_) {}
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    if (newTask == null) fail("Task 'New Task Test' not found in dataService");
    
    container.read(selectionProvider.notifier).selectTask(newTask.id);
    await tester.pumpAndSettle();
    
    // Exit Edit Mode for Task
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // 3. Subtasks Column
    // Navigate Right to Subtasks (Auto-creates subtask if empty)
    Focus.of(tester.element(find.byKey(const ValueKey('rootFocus')))).requestFocus();
    await tester.pumpAndSettle();

    container.read(selectionProvider.notifier).changeColumn(1);
    
    // Wait for subtask to appear in dataService
    bool subtaskCreated = false;
    for (int i=0; i<30; i++) {
      try {
        final p = dataService.projects.last;
        final t = p.tasks.firstWhere((t) => t.title == "New Task Test");
        if (t.subtasks.isNotEmpty) {
          subtaskCreated = true;
          break;
        }
      } catch (_) {}
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    if (!subtaskCreated) fail("Subtask not created after navigating right");

    // Wait for SelectionState to update editingItemId
    for (int i=0; i<10; i++) {
      if (container.read(selectionProvider).editingItemId != null) break;
      await tester.pump(const Duration(milliseconds: 100));
    }

    expect(find.text('Subtasks'), findsOneWidget);
    await tester.pumpAndSettle();
    
    final subtaskColumnFinder = find.ancestor(of: find.text('Subtasks'), matching: find.byType(EditableColumn)); 
    
    final subtaskTextFields = find.descendant(
      of: subtaskColumnFinder,
      matching: find.byType(TextField),
    );
    expect(subtaskTextFields, findsNWidgets(2));

    expect(tester.widget<TextField>(subtaskTextFields.first).focusNode?.hasFocus, isTrue);
    
    await tester.enterText(subtaskTextFields.first, "New Subtask Test");
    await tester.pump();
    expect(find.text("New Subtask Test"), findsOneWidget);
  });
}
