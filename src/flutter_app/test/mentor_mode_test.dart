import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/ai_wrapper.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter/services.dart';

class MockDataService extends Mock implements DataService {
  @override
  List<Project> get projects => [];
}

// Mock the Wrappers, NOT the final Firebase classes
class MockAIModelWrapper extends Mock implements AIModelWrapper {}
class MockChatSessionWrapper extends Mock implements ChatSessionWrapper {}

class FakeChatMessage extends Fake implements ChatMessage {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  
  setUpAll(() {
    registerFallbackValue(FakeChatMessage());
    registerFallbackValue(Content.text(''));
    // We might need to register fallback for Content if used in any() matcher
    // But Content is final, so we can't extend Fake implements Content easily?
    // Wait, earlier error said Content is final.
    // So FakeContent definition above might fail if Content is final!
    // I should check if Content is final.
    // If Content is final, I cannot mock/fake it.
    // But I can instantiate it! Content.text('foo').
    // So for registerFallbackValue, I can pass a real instance.
    registerFallbackValue(Content.text(''));
    
    const MethodChannel channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return 1; // Simplify
      },
    );
  });

  group('AssistantService Mentor Mode', () {
    late AssistantService service;
    late MockDataService mockDataService;
    late ToolRegistry registry;
    late MockAIModelWrapper mockModelWrapper;
    late MockChatSessionWrapper mockChatSession;

    setUp(() {
      mockDataService = MockDataService();
      mockModelWrapper = MockAIModelWrapper();
      mockChatSession = MockChatSessionWrapper();

      // Stub chat history methods
      when(() => mockDataService.getChatHistory(any())).thenAnswer((_) async => []);
      when(() => mockDataService.saveChatMessage(any(), any())).thenAnswer((_) async {});
      when(() => mockDataService.clearChatHistory(any())).thenAnswer((_) async {});
      
      // Stub Knowledge methods
      when(() => mockDataService.getAllKnowledge()).thenAnswer((_) async => []);
      when(() => mockDataService.saveKnowledge(any())).thenAnswer((_) async {});

      // Stub Wrapper
      when(() => mockModelWrapper.startChat(history: any(named: 'history')))
          .thenReturn(mockChatSession);
      
      // Stub Chat Session
      when(() => mockChatSession.sendMessage(any()))
          .thenAnswer((_) async => AIResponse(text: "Mock Response"));
          
      // Stub history getter
      when(() => mockChatSession.history).thenReturn([]);

      registry = ToolRegistry(mockDataService);
      
      // Inject Mock Wrapper
      service = AssistantService(mockDataService, registry, mockModelWrapper);
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
      
      // Verify response (Mock Response)
      expect(service.messages.any((m) => m.text == "Mock Response" && !m.isUser), true);
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
