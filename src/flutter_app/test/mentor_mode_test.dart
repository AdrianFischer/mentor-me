import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';

import 'package:flutter/services.dart';

class MockDataService extends Mock implements DataService {
  @override
  List<Project> get projects => [];
}

class FakeChatMessage extends Fake implements ChatMessage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    registerFallbackValue(FakeChatMessage());
    
    const MethodChannel channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        if (methodCall.method == 'speak') {
          return 1;
        }
        if (methodCall.method == 'awaitSpeakCompletion') {
          return 1;
        }
        if (methodCall.method == 'setLanguage') {
          return 1;
        }
        if (methodCall.method == 'setSpeechRate') {
          return 1;
        }
        if (methodCall.method == 'setVolume') {
          return 1;
        }
        if (methodCall.method == 'setPitch') {
          return 1;
        }
        if (methodCall.method == 'isLanguageAvailable') {
          return true;
        }
        if (methodCall.method == 'setIosAudioCategory') {
           return 1;
        }
        if (methodCall.method == 'setSharedInstance') {
           return 1;
        }
        return null;
      },
    );
  });

  group('AssistantService Mentor Mode', () {
    late AssistantService service;
    late MockDataService mockDataService;
    late ToolRegistry registry;

    setUp(() {
      mockDataService = MockDataService();
      // Stub chat history methods
      when(() => mockDataService.getChatHistory(any())).thenAnswer((_) async => []);
      when(() => mockDataService.saveChatMessage(any(), any())).thenAnswer((_) async {});
      when(() => mockDataService.clearChatHistory(any())).thenAnswer((_) async {});
      
      // Stub Knowledge methods
      when(() => mockDataService.getAllKnowledge()).thenAnswer((_) async => []);
      when(() => mockDataService.saveKnowledge(any())).thenAnswer((_) async {});

      registry = ToolRegistry(mockDataService);
      service = AssistantService(mockDataService, registry);
    });

    test('starts in Standard Mode', () {
      expect(service.isThinkingMode, false);
      expect(service.messages, isEmpty);
    });

    test('toggles to Thinking Mode', () {
      service.toggleThinking();
      expect(service.isThinkingMode, true);
    });

    test('switching modes preserves message history (Unified)', () async {
      // Add message in Standard Mode
      await service.sendMessage("Hello Assistant");
      expect(service.messages.isNotEmpty, true);
      final countBefore = service.messages.length;

      // Switch to Thinking
      service.toggleThinking();
      expect(service.isThinkingMode, true);
      
      // History should be preserved
      expect(service.messages.length, countBefore);
    });
    
    test('Mock Thinking Mode responds correctly', () async {
      service.toggleThinking(); // Switch to Thinking
      expect(service.isThinkingMode, true);

      // Send message
      await service.sendMessage("I'm stuck");
      
      // Verify user message added
      expect(service.messages.any((m) => m.text == "I'm stuck" && m.isUser), true);
      
      // Verify mock thinking response
      expect(service.messages.any((m) => m.text.contains("[Mock Thinking]") && !m.isUser), true);
    });

    test('Unified history across toggles', () async {
      // 1. Standard Mode
      await service.sendMessage("Assistant Task");
      final count1 = service.messages.length;
      expect(count1, greaterThan(0));

      // 2. Switch to Thinking
      service.toggleThinking();
      // History should NOT be empty
      expect(service.messages.length, count1);

      // 3. Thinking Mode Message
      await service.sendMessage("Mentor Help");
      final count2 = service.messages.length;
      expect(count2, greaterThan(count1));

      // 4. Switch back
      service.toggleThinking();
      // History should still be there
      expect(service.messages.length, count2);
    });
  });
}
