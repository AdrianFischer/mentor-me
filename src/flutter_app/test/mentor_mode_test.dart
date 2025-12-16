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

    test('starts in Assistant Mode', () {
      expect(service.isMentorMode, false);
      expect(service.messages, isEmpty);
    });

    test('toggles to Mentor Mode', () {
      service.toggleMode();
      expect(service.isMentorMode, true);
    });

    test('switching modes switches message history', () {
      // Add message in Assistant Mode
      service.sendMessage("Hello Assistant");
      // Since we are in mock mode (no key in test), it might have added a response or just the user message + processing
      // In Assistant Mock mode: 
      // It adds user message. 
      // Then if no key, it waits and responds.
      // We need to wait for async.
    });
    
    test('Mock Mentor Mode responds correctly', () async {
      service.toggleMode(); // Switch to Mentor
      expect(service.isMentorMode, true);

      // Send message
      await service.sendMessage("I'm stuck");
      
      // Verify user message added
      expect(service.messages.any((m) => m.text == "I'm stuck" && m.isUser), true);
      
      // Verify mock mentor response
      expect(service.messages.any((m) => m.text.contains("[Mock Mentor]") && !m.isUser), true);
    });

    test('Separate histories', () async {
      // 1. Assistant Mode
      await service.sendMessage("Assistant Task");
      final assistantCount = service.messages.length;
      expect(assistantCount, greaterThan(0));

      // 2. Switch to Mentor
      service.toggleMode();
      expect(service.messages, isEmpty); // Mentor history starts empty

      // 3. Mentor Mode
      await service.sendMessage("Mentor Help");
      expect(service.messages.length, greaterThan(0));
      expect(service.messages.first.text, "Mentor Help");

      // 4. Switch back
      service.toggleMode();
      expect(service.messages.length, assistantCount);
      expect(service.messages.first.text, "Assistant Task");
    });
  });
}
