import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';

void main() {
  testWidgets('Checked state persistence test', (WidgetTester tester) async {
    // 1. Build the app
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 2. Select "Inbox" Project
    // Projects column is first. "Inbox" is usually the first real project (index 1 after Assistant).
    // We can find it by text.
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    // 3. Find the checkbox for the first task "Check Emails"
    // The task list title is "Tasks".
    // The key format in EditableColumn is '${title.toLowerCase()}_check_$index'
    // So for the first item (index 0) in "Tasks" column: 'tasks_check_0'
    final checkboxFinder = find.byKey(const ValueKey('tasks_check_0'));
    expect(checkboxFinder, findsOneWidget);

    // 4. Tap the checkbox to check it
    await tester.tap(checkboxFinder);
    await tester.pumpAndSettle();

    // Verify visual state (Icon check should be visible)
    expect(find.descendant(of: checkboxFinder, matching: find.byIcon(Icons.check)), findsOneWidget);

    // 5. Navigate away to "Today" project
    await tester.tap(find.text('Today'));
    await tester.pumpAndSettle();

    // Verify we are in Today (Tasks should show "Morning Standup")
    expect(find.text('Morning Standup'), findsOneWidget);
    expect(find.text('Check Emails'), findsNothing);

    // 6. Navigate back to "Inbox"
    await tester.tap(find.text('Inbox'));
    await tester.pumpAndSettle();

    // 7. Verify "Check Emails" is still checked
    // We need to find the checkbox again
    final checkboxFinderBack = find.byKey(const ValueKey('tasks_check_0'));
    expect(checkboxFinderBack, findsOneWidget);
    
    // This expectation should fail if persistence is broken
    expect(find.descendant(of: checkboxFinderBack, matching: find.byIcon(Icons.check)), findsOneWidget);
  });
}




