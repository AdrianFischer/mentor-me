import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart'; // Import EditableColumn

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'GEMINI_API_KEY=dummy_key');
  });

  testWidgets('Enter key adds new items in all columns', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 1. Projects Column
    // Select first project ("Inbox")
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Select Assistant
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Select Inbox
    await tester.pumpAndSettle();
    
    // Verify initial projects count (Inbox, Today, Upcoming, Anytime, Someday = 5)
    expect(find.text("Inbox"), findsOneWidget);
    expect(find.text("Today"), findsOneWidget);
    
    // Press Enter to add new Project
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    // Verify new empty item added (TextField with empty text)
    // There are 5 initial projects. Now 6.
    
    // Check that the new item is FOCUSED
    // Since we updated logic to auto-focus, we should be able to type without finding the widget explicitly.
    // However, tester.enterText(finder, text) requires a finder.
    // To verify focus, we can check FocusManager.
    
    final projectTextFields = find.descendant(
      of: find.byKey(const ValueKey('projects')),
      matching: find.byType(TextField),
    );
    expect(projectTextFields, findsNWidgets(7));
    
    // Verify the last item is focused
    final lastProjectField = projectTextFields.last;
    final textFieldWidget = tester.widget<TextField>(lastProjectField);
    expect(textFieldWidget.focusNode?.hasFocus, isTrue);
    
    // Enter text "New Project Test" into the focused widget (simulating typing)
    // We use sendText or enterText on the finder.
    await tester.enterText(lastProjectField, "New Project Test");
    await tester.pump();
    expect(find.text("New Project Test"), findsOneWidget);

    // 2. Tasks Column
    // Navigate to Tasks
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    // Debug: Print found widgets
    // debugPrint("Finding Tasks column...");
    final tasksColumn = find.text('Tasks');
    expect(tasksColumn, findsOneWidget);
    
    // Press Enter to add new Task
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    // We expect a TextField in the Tasks column.
    // We don't rely on the Key 'tasks_5' being exact if we are unsure of index, 
    // but we know it's the second EditableColumn (index 1 in the Row).
    // Or we can find by ancestor Type.
    
    final allEditableColumns = find.byType(EditableColumn);
    // Should be 3 columns visible (Project, Task, Subtask) or 2?
    // Project is always visible.
    // Task is visible if project selected.
    // Subtask is visible if task selected.
    // We selected Project 5.
    // We just added a Task via Enter.
    // So now we have Project 5, Task 0.
    // So Subtask column should be visible too!
    
    expect(allEditableColumns, findsNWidgets(3));
    
    final taskColumnFinder = allEditableColumns.at(1); // 0 is Projects, 1 is Tasks
    final taskTextFields = find.descendant(
      of: taskColumnFinder,
      matching: find.byType(TextField),
    );
    
    // Initial: 0. Now: 2 (1 auto-created on nav, 1 added by Enter).
    expect(taskTextFields, findsNWidgets(2));
    
    // Verify focus on new task
    expect(tester.widget<TextField>(taskTextFields.last).focusNode?.hasFocus, isTrue);
    
    await tester.enterText(taskTextFields.last, "New Task Test");
    await tester.pump();
    expect(find.text("New Task Test"), findsOneWidget);
    
    // 3. Subtasks Column
    // Move to Subtasks
    // We just added a task "New Task Test".
    // AND `app.dart` logic now auto-selects it!
    // So `_selectedTaskIndex` is not null (it's 0).
    // So Subtasks column SHOULD be visible now.
    
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    // Check if Subtasks column is present
    expect(find.text('Subtasks'), findsOneWidget);
    
    // Subtasks column active. 0 items.
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.pumpAndSettle();
    
    final subtaskColumnFinder = find.byType(EditableColumn).at(2); // 0=Proj, 1=Task, 2=Subtask
    
    final subtaskTextFields = find.descendant(
      of: subtaskColumnFinder,
      matching: find.byType(TextField),
    );
    // Initial: 0. Now: 2 (1 auto-created on nav, 1 added by Enter).
    expect(subtaskTextFields, findsNWidgets(2));

    // Verify focus on new subtask
    expect(tester.widget<TextField>(subtaskTextFields.last).focusNode?.hasFocus, isTrue);
    
    await tester.enterText(subtaskTextFields.last, "New Subtask Test");
    await tester.pump();
    expect(find.text("New Subtask Test"), findsOneWidget);

  });
}

