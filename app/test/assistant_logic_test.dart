import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_app/models/ai_models.dart';

void main() {
  group('AI Assistant Logic Tests', () {
    test('ProposedAction model creation', () {
      final action = ProposedAction(
        description: 'Test Action',
        toolName: 'test_tool',
        toolArgs: {'arg': 1},
      );

      expect(action.id, isNotEmpty);
      expect(action.description, 'Test Action');
      expect(action.toolName, 'test_tool');
      expect(action.toolArgs['arg'], 1);
    });

    test('ChatMessage model creation', () {
      final msg = ChatMessage(text: 'Hello', isUser: true);
      expect(msg.id, isNotEmpty);
      expect(msg.text, 'Hello');
      expect(msg.isUser, true);
      expect(msg.timestamp, isNotNull);
    });
  });
}
