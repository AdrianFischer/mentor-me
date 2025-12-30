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

    // 1. Projects Column
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); 
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); 
    await tester.pumpAndSettle();
    
    expect(find.text("Inbox"), findsOneWidget);
    
    // Press Cmd+N to add new Project
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();
    
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
    
    expect(taskTextFields, findsNWidgets(2));
    expect(tester.widget<TextField>(taskTextFields.first).focusNode?.hasFocus, isTrue);
    
    await tester.enterText(taskTextFields.first, "New Task Test");
    await tester.pump();
    expect(find.text("New Task Test"), findsOneWidget);
    
    // Exit Edit Mode
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

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
    expect(subtaskTextFields, findsNWidgets(2));

    expect(tester.widget<TextField>(subtaskTextFields.first).focusNode?.hasFocus, isTrue);
    
    await tester.enterText(subtaskTextFields.first, "New Subtask Test");
    await tester.pump();
    expect(find.text("New Subtask Test"), findsOneWidget);
  });
}
