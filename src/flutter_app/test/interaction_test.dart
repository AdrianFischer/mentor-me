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

  testWidgets('Navigation, Typing, and Checkbox Toggle Test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // Verify initial state: Project column active, Task/Subtask empty/inactive
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Tasks'), findsNothing); // Hidden until project selected

    // 1. Test Navigation & Selection in Column 1 (Projects)
    // Initially no selection? App.dart initializes _selectedProjectIndex = null?
    // Let's check App.dart.
    // Actually, App.dart doesn't init selection, but EditableColumn has items.
    // If I press ArrowDown, it should select "AI Assistant" (Index 0).
    // I need to press ArrowDown TWICE to select "Inbox" (Index 1).
    
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Select Assistant
    await tester.pumpAndSettle();
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowDown); // Select Inbox
    await tester.pumpAndSettle();
    
    // Verify "Inbox" is selected (first item in Projects)
    // We can check if "Tasks" column appeared, which happens only if project selected.
    expect(find.text('Tasks'), findsOneWidget);

    // 2. Test Typing in Project Column
    // Enter text "New Project"
    await tester.enterText(find.byType(TextField).first, 'New Project');
    await tester.pump();
    expect(find.text('New Project'), findsOneWidget);

    // 3. Test Cmd+Enter Key Toggles Checkbox
    // Check initial state (unchecked)
    // We can't easily check internal state, but we can check visual (icon).
    expect(find.byIcon(Icons.check), findsNothing);

    // Press Cmd+Enter
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();

    // Verify Checkmark appears
    expect(find.byIcon(Icons.check), findsOneWidget);

    // Press Cmd+Enter again to uncheck
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();
    expect(find.byIcon(Icons.check), findsNothing);

    // 4. Test Navigation to Column 2 (Tasks)
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    // Verify focus moved (Task column active). 
    // Tasks column should auto-select first item if it was empty selection.
    // Verify "Tasks" title is black (active). "Projects" title should be grey.
    // We can check if we can type in Tasks column.
    
    // The first TextField in Tasks column (which is the 6th TextField overall, since Projects has 5+1)
    // Actually finding by text "Check Emails" is better.
    expect(find.text('Check Emails'), findsOneWidget); // Verify text exists first
    final taskItemFinder = find.widgetWithText(TextField, 'Check Emails');
    expect(taskItemFinder, findsOneWidget);

    // Type in Task Item 1
    await tester.enterText(taskItemFinder, 'Buy Milk');
    await tester.pump();
    expect(find.text('Buy Milk'), findsOneWidget);

    // Test Checkbox in Column 2
    // Send Done action to the specific TextField
    // We need to update finder because text changed
    final taskItemFinderUpdated = find.widgetWithText(TextField, 'Buy Milk');
    await tester.showKeyboard(taskItemFinderUpdated);
    // Press Cmd+Enter
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();
    
    // Should see a checkmark now
    expect(find.byIcon(Icons.check), findsOneWidget);

    // 5. Test Navigation to Column 3 (Subtasks)
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
    await tester.pumpAndSettle();

    // Verify "Subtasks" column visible
    expect(find.text('Subtasks'), findsOneWidget);
    
    // Check Emails has "Reply to Boss" as first subtask
    // But wait, we renamed "Check Emails" to "Buy Milk" in previous step!
    // So "Buy Milk" (was Check Emails) has subtasks.
    // "Reply to Boss" should be there.
    
    final subtaskItemFinder = find.widgetWithText(TextField, 'Reply to Boss');
    expect(subtaskItemFinder, findsOneWidget);

    // Type in Subtask
    await tester.enterText(subtaskItemFinder, 'Check Expiry');
    await tester.pump();
    expect(find.text('Check Expiry'), findsOneWidget);

    // Test Checkbox in Column 3
    final subtaskItemFinderUpdated = find.widgetWithText(TextField, 'Check Expiry');
    await tester.showKeyboard(subtaskItemFinderUpdated);
    // Press Cmd+Enter
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();
    
    // Should see checkmark (total 2 now, one in task, one in subtask)
    expect(find.byIcon(Icons.check), findsNWidgets(2)); 

    // 6. Navigate Back
    await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
    await tester.pumpAndSettle();
    
    // Verify we are back in Tasks column
    // Try toggling check of 'Buy Milk' off
    await tester.showKeyboard(find.widgetWithText(TextField, 'Buy Milk'));
    // Press Cmd+Enter
    await tester.sendKeyDownEvent(LogicalKeyboardKey.meta);
    await tester.sendKeyEvent(LogicalKeyboardKey.enter);
    await tester.sendKeyUpEvent(LogicalKeyboardKey.meta);
    await tester.pump();
    
    // Should be 1 checkmark left (in subtask)
    expect(find.byIcon(Icons.check), findsOneWidget);

  });
}

