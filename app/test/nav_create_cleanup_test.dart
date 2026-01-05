import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';
import 'package:flutter_app/ui/widgets/editable_item_widget.dart';
import 'package:flutter_app/ui/actions/selection_actions.dart';
import 'package:flutter_app/data/repository/storage_repository.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/providers/data_provider.dart';
import 'package:flutter_app/services/mcp_server.dart';
import 'package:flutter_app/providers/mcp_provider.dart';
import 'package:mocktail/mocktail.dart';
import 'helpers/fake_storage_repository.dart';

class MockMcpServerService extends Mock implements McpServerService {
  @override
  Future<void> start({int? port, int? retries}) async {}

  @override
  Future<void> stop() async {}
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
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();
    
    // Exit Edit Mode
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Ensure focus on root to trigger shortcuts
    Focus.of(tester.element(find.byKey(const ValueKey('rootFocus')))).requestFocus();
    await tester.pumpAndSettle();

    // 2. Navigate Right -> Should create a Task
    // await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.runAsync(() async {
       Actions.invoke(
         tester.element(find.byKey(const ValueKey('rootFocus'))),
         const ChangeColumnIntent(1)
       );
    });
    
    // Pump multiple times to allow async logic to settle without hanging on pumpAndSettle
    for (int i=0; i<10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    // Check Tasks column
    expect(find.text('Tasks'), findsOneWidget);
    
    // Should have 2 TextFields (Title + Notes) because it's in Edit Mode
    final taskColumnFinder = find.ancestor(
      of: find.text('Tasks'),
      matching: find.byType(EditableColumn),
    );
    final taskTextFields = find.descendant(
      of: taskColumnFinder,
      matching: find.byType(TextField),
    );
    expect(taskTextFields, findsNWidgets(2));
    
    // Verify focus (Title should be focused)
    expect(tester.widget<TextField>(taskTextFields.first).focusNode?.hasFocus, isTrue);
    
    // Exit Edit Mode for Task
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // 3. Navigate Right -> Should create a Subtask
    // await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.runAsync(() async {
       Actions.invoke(
         tester.element(find.byKey(const ValueKey('rootFocus'))),
         const ChangeColumnIntent(1)
       );
    });
    
    for (int i=0; i<10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    expect(find.text('Subtasks'), findsOneWidget);
    
    final subtaskColumnFinder = find.ancestor(
      of: find.text('Subtasks'),
      matching: find.byType(EditableColumn),
    );
    final subtaskTextFields = find.descendant(
      of: subtaskColumnFinder,
      matching: find.byType(TextField),
    );
    expect(subtaskTextFields, findsNWidgets(2));
    
    // Verify focus
    expect(tester.widget<TextField>(subtaskTextFields.first).focusNode?.hasFocus, isTrue);

  });

  testWidgets('Cleanup Empty Items on Navigation', (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1400, 1000);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

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
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();
    
    // We have an empty project selected.
    // 2. Create another new project
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.keyN);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pumpAndSettle();
    
    final projectItems = find.descendant(
      of: find.byKey(const ValueKey('projects')),
      matching: find.byType(EditableItemWidget),
    );
    
    int countBeforeMove = projectItems.evaluate().length;
    
    // Exit Edit Mode
    await tester.sendKeyEvent(LogicalKeyboardKey.escape);
    await tester.pumpAndSettle();

    // Ensure focus on root
    Focus.of(tester.element(find.byKey(const ValueKey('rootFocus')))).requestFocus();
    await tester.pumpAndSettle();

    // 3. Move Up. 
    // await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.runAsync(() async {
       Actions.invoke(
         tester.element(find.byKey(const ValueKey('rootFocus'))),
         const MoveSelectionIntent(-1)
       );
    });
    
    for (int i=0; i<10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }
    
    int countAfterMove = projectItems.evaluate().length;
    
    // We expect count to decrease by 1.
    expect(countAfterMove, countBeforeMove - 1);
  });
}
