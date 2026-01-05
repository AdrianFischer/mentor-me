import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';

import 'package:flutter_app/app.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/services/markdown_persistence_service.dart';
import 'package:flutter_app/ui/widgets/editable_item_widget.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'helpers/fake_storage_repository.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
}

class MockMarkdownPersistence extends Mock implements MarkdownPersistenceService {
  @override
  bool get isEnabled => true;
  @override
  Future<void> saveProject(Project p) async {}
  @override
  Future<void> deleteProject(Project p) async {}
}

void main() {
  testWidgets('Repro: Escaping edit mode then pressing Left Arrow should navigate up immediately', (WidgetTester tester) async {
    // Setup
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Create Project with one Task
    final task1 = Task(id: 't1', title: 'Task 1');
    final projectA = Project(id: 'p1', title: 'Project A', tasks: [task1]);

    final mockStorage = FakeStorageRepository(initialProjects: [projectA]);
    final mockMarkdown = MockMarkdownPersistence();
    final dataService = DataService(mockStorage, mockMarkdown);
    await dataService.initData();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWith((ref) => dataService),
          mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
        ],
        child: MyApp(initialSelectedProjectId: 'p1', initialIsAssistantActive: false),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Select the Task
    // Initially Project A is selected (or at least loaded).
    // We need to navigate to Task 1.
    // Assuming UI structure: Col 0 = Projects, Col 1 = Tasks.
    // Project A is likely selected by default if passed in initialSelectedProjectId.
    
    // Verify Project A is selected
    final projectItemFinder = find.byWidgetPredicate((widget) => 
      widget is EditableItemWidget && 
      widget.item.id == 'p1' && 
      widget.isSelected
    );
    expect(projectItemFinder, findsOneWidget, reason: "Project A should be initially selected");

    // Navigate Right to Task 1
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    // Verify Task 1 is selected
    final taskItemFinder = find.byWidgetPredicate((widget) => 
      widget is EditableItemWidget && 
      widget.item.id == 't1' && 
      widget.isSelected
    );
    expect(taskItemFinder, findsOneWidget, reason: "Task 1 should be selected after moving right");

    // 2. Press Enter to Edit Task 1
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // Verify Task 1 is in edit mode (TextField has focus)
    final taskTextFieldFinder = find.byWidgetPredicate((widget) => 
      widget is TextField && 
      widget.controller?.text == 'Task 1' &&
      widget.focusNode?.hasFocus == true
    );
    expect(taskTextFieldFinder, findsOneWidget, reason: "Task 1 should be in edit mode");

    // 3. Press Esc to exit Edit Mode
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Verify Task 1 is still selected but NOT editing
    expect(taskItemFinder, findsOneWidget);
    final taskTextFieldPostEsc = find.byWidgetPredicate((widget) => 
      widget is TextField && 
      widget.controller?.text == 'Task 1' &&
      widget.focusNode?.hasFocus == true
    );
    // Note: When not editing, the EditableItemWidget might not have a focused TextField, 
    // or it keeps focus but isEditing is false.
    // Actually, in this app, when isEditing is false, the FocusNode of the item (or Row) might have focus?
    // Or the FocusNode is on the TextField but it's read-only? 
    // Let's rely on behavior: Left Arrow should work.

    // 4. Press Left Arrow ONCE
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();

    // 5. Verify Project A is selected
    final projectItemFinderFinal = find.byWidgetPredicate((widget) => 
      widget is EditableItemWidget && 
      widget.item.id == 'p1' && 
      widget.isSelected
    );
    
    // THIS EXPECTATION SHOULD FAIL currently if the bug exists
    expect(projectItemFinderFinal, findsOneWidget, reason: "Project A should be selected after pressing Left Arrow once");
  });

  testWidgets('Repro: Escaping edit mode then pressing Right Arrow should navigate down immediately', (WidgetTester tester) async {
    // Setup
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    // Create Task with one Subtask
    final subtask1 = Subtask(id: 'st1', title: 'Subtask 1');
    final task1 = Task(id: 't1', title: 'Task 1', subtasks: [subtask1]);
    final projectA = Project(id: 'p1', title: 'Project A', tasks: [task1]);

    final mockStorage = FakeStorageRepository(initialProjects: [projectA]);
    final mockMarkdown = MockMarkdownPersistence();
    final dataService = DataService(mockStorage, mockMarkdown);
    await dataService.initData();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          dataServiceProvider.overrideWith((ref) => dataService),
          mcpServerProvider.overrideWith((ref) => MockMcpServerService()),
        ],
        child: MyApp(initialSelectedProjectId: 'p1', initialIsAssistantActive: false),
      ),
    );
    await tester.pumpAndSettle();

    // 1. Navigate to Task 1
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    // Verify Task 1 is selected
    final taskItemFinder = find.byWidgetPredicate((widget) => 
      widget is EditableItemWidget && 
      widget.item.id == 't1' && 
      widget.isSelected
    );
    expect(taskItemFinder, findsOneWidget);

    // 2. Press Enter to Edit Task 1
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();

    // 3. Press Esc to exit Edit Mode
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // 4. Press Right Arrow ONCE
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    // 5. Verify Subtask 1 is selected
    final subtaskItemFinder = find.byWidgetPredicate((widget) => 
      widget is EditableItemWidget && 
      widget.item.id == 'st1' && 
      widget.isSelected
    );
    
    expect(subtaskItemFinder, findsOneWidget, reason: "Subtask 1 should be selected after pressing Right Arrow once");
  });
}