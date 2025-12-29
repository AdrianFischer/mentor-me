import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/ui/widgets/editable_item_widget.dart';

void main() {
  group('Hierarchical Navigation Tests', () {
    late TextEditingController controller;

    setUp(() {
      controller = TextEditingController();
    });

    testWidgets('Left Arrow at start of text triggers onNavigateLeft', (WidgetTester tester) async {
      bool navigatedLeft = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableItemWidget(
              item: EditableItem(id: '1', text: 'Task'),
              isSelected: true,
              isActiveColumn: true,
              index: 0,
              onChanged: (_) {},
              onTap: () {},
              onSubmitted: () {},
              onToggleCheck: () {},
              onDelete: () {},
              onNavigateLeft: () {
                navigatedLeft = true;
              },
            ),
          ),
        ),
      );

      // Focus the widget
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Ensure cursor is at start
      final TextField textField = tester.widget(find.byType(TextField));
      textField.controller!.selection = const TextSelection.collapsed(offset: 0);
      await tester.pump();

      // Press Left Arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      await tester.pump();

      expect(navigatedLeft, isTrue, reason: 'Should trigger onNavigateLeft when cursor is at start');
    });

    testWidgets('Right Arrow at end of text triggers onNavigateRight', (WidgetTester tester) async {
      bool navigatedRight = false;
      const String text = 'Task';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableItemWidget(
              item: EditableItem(id: '1', text: text),
              isSelected: true,
              isActiveColumn: true,
              index: 0,
              onChanged: (_) {},
              onTap: () {},
              onSubmitted: () {},
              onToggleCheck: () {},
              onDelete: () {},
              onNavigateRight: () {
                navigatedRight = true;
              },
            ),
          ),
        ),
      );

      // Focus
      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Ensure cursor is at end
      final TextField textField = tester.widget(find.byType(TextField));
      textField.controller!.selection = const TextSelection.collapsed(offset: text.length);
      await tester.pump();

      // Press Right Arrow
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      await tester.pump();

      expect(navigatedRight, isTrue, reason: 'Should trigger onNavigateRight when cursor is at end');
    });

    testWidgets('Arrow keys inside text DO NOT trigger navigation', (WidgetTester tester) async {
      bool navigatedLeft = false;
      bool navigatedRight = false;
      const String text = 'Middle';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EditableItemWidget(
              item: EditableItem(id: '1', text: text),
              isSelected: true,
              isActiveColumn: true,
              index: 0,
              onChanged: (_) {},
              onTap: () {},
              onSubmitted: () {},
              onToggleCheck: () {},
              onDelete: () {},
              onNavigateLeft: () => navigatedLeft = true,
              onNavigateRight: () => navigatedRight = true,
            ),
          ),
        ),
      );

      await tester.tap(find.byType(TextField));
      await tester.pump();

      // Cursor in middle
      final TextField textField = tester.widget(find.byType(TextField));
      textField.controller!.selection = const TextSelection.collapsed(offset: 2);
      await tester.pump();

      // Press Left
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowLeft);
      expect(navigatedLeft, isFalse);

      // Press Right
      await tester.sendKeyEvent(LogicalKeyboardKey.arrowRight);
      expect(navigatedRight, isFalse);
    });
  });
}