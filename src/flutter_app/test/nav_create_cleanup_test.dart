import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'GEMINI_API_KEY=dummy_key');
  });

  testWidgets('Navigation Right Auto-Creates Item', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 1. Create a new project (empty)
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    // We are on the new project "Project X" (actually empty title).
    // It has no tasks.
    
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
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
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
    
    // debugPrint("Total projects found: ${projectTextFields.evaluate().length}");
    
    // Based on debugging, initial data might not load, so we might only have our 2 created items.
    // Or we might have 5 defaults + 1 (last created) = 6 (previous empty one cleaned).
    // Let's use the actual count to verify the DELTA.
    int countBeforeMove = projectTextFields.evaluate().length;
    
    // 3. Move Up. 
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);
    await tester.pumpAndSettle();
    
    int countAfterMove = projectTextFields.evaluate().length;
    
    // Since we moved up from an empty item, the empty item (last one) is now NOT selected.
    // So it should be removed.
    // If it found 2 before move, and 2 after move, it means cleanup didn't happen OR selection didn't move as expected.
    
    final firstTextField = tester.widget<TextField>(projectTextFields.first);
    final lastTextField = tester.widget<TextField>(projectTextFields.last);
    // Since we create "New Item" hint but text is empty?
    // debugPrint("Item 0 Text: '${firstTextField.controller?.text}'");
    // debugPrint("Item 1 Text: '${lastTextField.controller?.text}'");
    
    // We expect count to decrease by 1.
    expect(countAfterMove, countBeforeMove - 1);
    
  });
}
