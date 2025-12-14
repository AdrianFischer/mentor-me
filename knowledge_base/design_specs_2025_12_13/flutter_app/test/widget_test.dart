import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/app.dart';
import 'package:flutter_app/widgets/editable_column.dart';

void main() {
  testWidgets('App smoke test', (WidgetTester tester) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify initial state (Projects column exists, others empty)
    expect(find.text('Projects'), findsOneWidget);
    expect(find.text('Select a Project'), findsOneWidget);
    expect(find.text('Select a Task'), findsOneWidget);

    // Tap first project to reveal Tasks
    await tester.tap(find.byType(TextField).first);
    await tester.pump();

    // Verify Tasks column appears
    expect(find.text('Tasks'), findsOneWidget);
    expect(find.text('Select a Task'), findsOneWidget);

    // Tap first task (in the second column)
    // Note: finding by text "Tasks Item 1" because EditableColumn init logic adds title to dummy items
    await tester.tap(find.widgetWithText(TextField, 'Tasks Item 1'));
    await tester.pump();

    // Verify Subtasks column appears
    expect(find.text('Subtasks'), findsOneWidget);
  });
}
