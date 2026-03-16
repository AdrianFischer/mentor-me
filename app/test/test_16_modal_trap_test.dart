import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Test 16: Keyboard Navigation Modal Trap Test', () {
    testWidgets('Opening a modal traps focus and closing it restores focus',
        (tester) async {
      // Create a test application with a TextField and a button to show a dialog.
      final FocusNode textFieldFocusNode = FocusNode(debugLabel: 'MainTextField');
      final FocusNode dialogButtonFocusNode = FocusNode(debugLabel: 'DialogButton');

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                TextField(
                  key: const ValueKey('background_textfield'),
                  focusNode: textFieldFocusNode,
                  autofocus: true,
                ),
                Builder(
                  builder: (context) => ElevatedButton(
                    key: const ValueKey('open_dialog_button'),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (BuildContext context) {
                          return AlertDialog(
                            title: const Text('Modal Dialog'),
                            content: const Text('This is a modal'),
                            actions: <Widget>[
                              ElevatedButton(
                                key: const ValueKey('close_dialog_button'),
                                focusNode: dialogButtonFocusNode,
                                autofocus: true,
                                child: const Text('Close'),
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                              ),
                            ],
                          );
                        },
                      );
                    },
                    child: const Text('Open Dialog'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Ensure the background text field has focus initially.
      expect(textFieldFocusNode.hasFocus, isTrue,
          reason: 'Text field should have initial focus');

      // Tap the button to open the dialog.
      await tester.tap(find.byKey(const ValueKey('open_dialog_button')));
      await tester.pumpAndSettle();

      // Verify the dialog is visible.
      expect(find.text('Modal Dialog'), findsOneWidget);

      // Verify that focus is trapped in the dialog (background text field loses focus).
      expect(textFieldFocusNode.hasFocus, isFalse,
          reason: 'Text field should lose focus when modal is open');
      expect(dialogButtonFocusNode.hasFocus, isTrue,
          reason: 'Dialog button should have focus when modal is open');

      // Attempt background interaction by simulating a key press that would normally go to the text field.
      // Since focus is trapped, this should not affect the text field.
      await tester.sendKeyEvent(LogicalKeyboardKey.keyA);
      await tester.pumpAndSettle();
      
      final TextField textField = tester.widget(find.byKey(const ValueKey('background_textfield')));
      expect(textField.controller?.text ?? '', isEmpty, 
          reason: 'Background text field should not receive keyboard input while modal is open');

      // Close the dialog.
      await tester.tap(find.byKey(const ValueKey('close_dialog_button')));
      await tester.pumpAndSettle();

      // Verify the dialog is closed.
      expect(find.text('Modal Dialog'), findsNothing);

      // Verify that focus is restored to the previously active UI element (the text field).
      expect(textFieldFocusNode.hasFocus, isTrue,
          reason: 'Text field should regain focus after modal is closed');
    });
  });
}
