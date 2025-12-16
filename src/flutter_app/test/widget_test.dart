import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/ui/widgets/editable_column.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const ProviderScope(child: MyApp()));

    // Verify initial state (Projects column exists, others empty)
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Select a Project'), findsOneWidget);
    expect(find.text('Select a Task'), findsOneWidget);

    // Tap "Inbox" project to reveal Tasks (Assistant is first, Inbox is second)
    await tester.tap(find.widgetWithText(TextField, 'Inbox'));
    await tester.pump();

    // Verify Tasks column appears
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Select a Task'), findsOneWidget);

    // Tap first task (in the second column)
    // Finding by text "Check Emails" which is in the initial data in App.dart
    await tester.tap(find.widgetWithText(TextField, 'Check Emails'));
    await tester.pump();

    // Verify Subtasks column appears
    expect(find.text('Subtasks'), findsOneWidget);
  });
}
