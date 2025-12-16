import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';

void main() {
  testWidgets('Deletion Test', (WidgetTester tester) async {
    // Build the app
    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    // 1. Select Project "Inbox" (First item)
    // Projects are: Inbox, Today, Upcoming...
    await tester.tap(find.widgetWithText(TextField, 'Inbox'));
    await tester.pumpAndSettle();

    // Verify Tasks are visible
    expect(find.text('Check Emails'), findsOneWidget);

    // 2. Test Deletion of a Task
    // We want to delete "Pay Bills" (Second task)
    // First, verify it exists
    expect(find.text('Pay Bills'), findsOneWidget);

    // Focus "Pay Bills"
    final payBillsFinder = find.widgetWithText(TextField, 'Pay Bills');
    await tester.tap(payBillsFinder);
    await tester.pumpAndSettle();

    // Clear text first (Backspace deletion only triggers on empty text)
    // Note: `enterText` replaces text. So enter empty string.
    await tester.enterText(payBillsFinder, '');
    await tester.pump();
    
    // Now press Backspace
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();

    // Verify "Pay Bills" is gone
    expect(find.text('Pay Bills'), findsNothing);
    
    // Verify "Check Emails" is still there
    expect(find.text('Check Emails'), findsOneWidget);

    // Verify selection/focus moved (probably to Check Emails or none, depending on logic)
    // Logic: if index > 0, move to index - 1. Pay Bills was index 1. Should move to index 0 (Check Emails).
    // Let's check if Check Emails is focused?
    // Hard to check focus directly without finding the specific widget instance's focus node, 
    // but we can check if typing types into Check Emails?
    // Or just be happy it's gone.

    // 3. Test Deletion of Project
    // Focus "Today" project
    await tester.tap(find.widgetWithText(TextField, 'Today'));
    await tester.pumpAndSettle();
    
    // Clear "Today"
    await tester.enterText(find.widgetWithText(TextField, 'Today'), '');
    await tester.pump();
    
    // Backspace
    await tester.sendKeyEvent(LogicalKeyboardKey.backspace);
    await tester.pumpAndSettle();
    
    // Verify "Today" is gone
    expect(find.text('Today'), findsNothing);
    
    // Verify "Inbox" is still there
    expect(find.text('Inbox'), findsOneWidget);

  });
}

