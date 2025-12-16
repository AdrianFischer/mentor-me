import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_app/app.dart';

void main() {
  setUpAll(() {
    dotenv.testLoad(fileInput: 'GEMINI_API_KEY=dummy_key');
  });

  testWidgets('Hierarchical Navigation and Content Update Test', (WidgetTester tester) async {
    // 1. Build the app
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 2. Initial State
    // Projects column should be visible
    expect(find.text('Projects'), findsOneWidget);
    // Task column placeholder should be visible (as no project is selected initially)
    expect(find.text('Select a Project'), findsOneWidget);
    expect(find.text('Tasks'), findsNothing);
    
    // 3. Select First Project ("Inbox")
    // Down once -> Assistant. Down twice -> Inbox.
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();

    // Now Tasks column should be visible
    expect(find.text('Tasks'), findsOneWidget);
    // Verify Inbox contents
    expect(find.widgetWithText(TextField, 'Inbox'), findsOneWidget); // Project selected
    expect(find.widgetWithText(TextField, 'Check Emails'), findsOneWidget); // Task 1
    expect(find.widgetWithText(TextField, 'Pay Bills'), findsOneWidget);    // Task 2
    
    // 4. Navigate to Tasks and Select First Task
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    // First task 'Check Emails' should be auto-selected or we select it
    // In current impl, entering column auto-selects if empty.
    // Verify Subtasks column appears
    expect(find.text('Subtasks'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Reply to Boss'), findsOneWidget); // Subtask 1
    
    // 5. Change Project Selection -> Should Update Tasks
    // Go back to Projects
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    
    // Move down to "Today" project
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown);
    await tester.pumpAndSettle();
    
    // Verify Project changed
    expect(find.widgetWithText(TextField, 'Today'), findsOneWidget);
    
    // Verify Tasks updated (Should see "Morning Standup", NOT "Check Emails")
    expect(find.widgetWithText(TextField, 'Morning Standup'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Check Emails'), findsNothing);
    
    // Verify Subtasks column reset (should show placeholder or empty)
    // Since we just switched project, task selection is reset to null.
    // So Subtasks column should show "Select a Task"
    expect(find.text('Select a Task'), findsOneWidget);
    expect(find.text('Subtasks'), findsNothing);

    // 6. Navigate to Tasks of "Today" and select a task
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();
    
    // "Morning Standup" should be selected (auto-select first)
    // Verify its subtasks
    expect(find.text('Subtasks'), findsOneWidget);
    expect(find.widgetWithText(TextField, 'Prepare updates'), findsOneWidget);
    
    // 7. Switch Task -> Should Update Subtasks
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Select "Code Review"
    await tester.pumpAndSettle();
    
    // Verify Task changed
    expect(find.widgetWithText(TextField, 'Code Review'), findsOneWidget);
    
    // "Code Review" has no subtasks. Subtask list should be empty (except new item placeholder) or just "New Item"
    expect(find.widgetWithText(TextField, 'Prepare updates'), findsNothing);
    
    // 8. Test Adding a New Item (Persistence Check)
    // Go back to Projects, select "Inbox" again
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft); // Back to Tasks
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft); // Back to Projects
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowUp);   // Select "Inbox"
    await tester.pumpAndSettle();
    
    // Verify "Inbox" tasks again
    expect(find.widgetWithText(TextField, 'Check Emails'), findsOneWidget);
    
    // Add a new Task to "Inbox"
    // Find the Add button in the Tasks column. 
    // There are multiple add buttons (one per column). We need the second one (Tasks).
    // The columns are: Projects, Tasks, Subtasks.
    // The Add button is an IconButton with icon add_circle.
    final addButtons = find.byIcon(Icons.add_circle);
    expect(addButtons, findsWidgets);
    
    // Tap the second add button (index 1) which corresponds to Tasks column
    await tester.tap(addButtons.at(1));
    await tester.pumpAndSettle();
    
    // A new item should appear at the bottom.
    // We can enter text into the last TextField of the Tasks column.
    // Finding the last TextField is tricky with generic finders.
    // But we know it receives focus.
    await tester.enterText(find.byType(TextField).last, 'New Inbox Task');
    await tester.pumpAndSettle();
    
    // Now navigate away to "Today" project
    // Note: Since we are in a TextField, Arrow keys might be captured by the text cursor.
    // We should use Tap to switch selection reliably in this test scenario.
    await tester.tap(find.widgetWithText(TextField, 'Today'));
    await tester.pumpAndSettle();
    
    // Verify "New Inbox Task" is NOT visible (we are in "Today")
    expect(find.text('New Inbox Task'), findsNothing);
    
    // Navigate back to "Inbox"
    await tester.tap(find.widgetWithText(TextField, 'Inbox'));
    await tester.pumpAndSettle();
    
    // Verify "New Inbox Task" IS visible (Persistence check)
    expect(find.text('New Inbox Task'), findsOneWidget);
  });
}

