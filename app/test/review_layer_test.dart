import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/ai_wrapper.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:firebase_ai/firebase_ai.dart';

import 'package:flutter_app/services/tts_service.dart';

class MockDataService extends Mock implements DataService {
  @override
  final NodeService nodeService = MockNodeService();
}
class MockNodeService extends Mock implements NodeService {}

class MockAIModelWrapper extends Mock implements AIModelWrapper {}
class MockChatSessionWrapper extends Mock implements ChatSessionWrapper {}
class MockTtsService extends Mock implements TtsService {
  @override
  Future<void> dispose() async {}
  @override
  Future<void> stop() async {}
}

class FakeChatMessage extends Fake implements ChatMessage {}
class FakeProposedAction extends Fake implements ProposedAction {}
class FakeKnowledge extends Fake implements Knowledge {}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() {
    registerFallbackValue(FakeChatMessage());
    registerFallbackValue(FakeProposedAction());
    registerFallbackValue(FakeKnowledge());
    registerFallbackValue(Content.text('')); // Content is final, use instance

    const MethodChannel channel = MethodChannel('flutter_tts');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger.setMockMethodCallHandler(
      channel,
      (MethodCall methodCall) async {
        return 1;
      },
    );
  });

  group('Review Layer (Mock Mode)', () {
    late AssistantService service;
    late MockDataService mockDataService;
    late ToolRegistry registry;
    late MockAIModelWrapper mockModelWrapper;
    late MockChatSessionWrapper mockChatSession;
    late MockTtsService mockTtsService;

    late MockNodeService mockNodeService;

    setUp(() {
      mockDataService = MockDataService();
      mockNodeService = mockDataService.nodeService as MockNodeService;
      mockModelWrapper = MockAIModelWrapper();
      mockChatSession = MockChatSessionWrapper();
      mockTtsService = MockTtsService();

      when(() => mockNodeService.rootNodes).thenReturn([]);
      when(() => mockNodeService.addChild(any(), any())).thenAnswer((_) async => 'new_id');


      // Stub TtsService
      when(() => mockTtsService.generateAndGetUrl(
        text: any(named: 'text'),
        languageCode: any(named: 'languageCode'),
      )).thenAnswer((_) async => "http://mock.url");
      when(() => mockTtsService.playUrl(any())).thenAnswer((_) async {});

      // Stub history and knowledge
      when(() => mockDataService.getChatHistory(any(), conversationId: any(named: 'conversationId')))
          .thenAnswer((_) async => []);
      when(() => mockDataService.saveChatMessage(any(), any())).thenAnswer((_) async {});
      when(() => mockDataService.clearChatHistory(any(), conversationId: any(named: 'conversationId')))
          .thenAnswer((_) async {});
      when(() => mockDataService.getAllKnowledge()).thenAnswer((_) async => []);

      // Stub tool execution (update_notes via NodeService)
      when(() => mockNodeService.updateNotes(any(), any())).thenReturn(null);

      when(() => mockDataService.createConversation(any())).thenReturn('conv_id');

      // Stub Wrapper
      when(() => mockModelWrapper.startChat(history: any(named: 'history'))).thenReturn(mockChatSession);
      when(() => mockChatSession.history).thenReturn([]);

      registry = ToolRegistry(mockNodeService, mockDataService);
      service = AssistantService(mockDataService, registry, mockModelWrapper, ttsService: mockTtsService);
    });

    test('Modification request adds to pendingActions instead of executing', () async {
      // Mock response with function call
      final functionCall = FunctionCall('update_notes', {'item_id': 'item-1', 'notes': 'New notes'});
      
      var callCount = 0;
      when(() => mockChatSession.sendMessage(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
             return AIResponse(text: null, functionCalls: [functionCall]);
          } else {
             return AIResponse(text: "Okay", functionCalls: []);
          }
      });

      expect(service.pendingActions, isEmpty);
      expect(service.executedActions, isEmpty);

      // Send a request that triggers "update_notes"
      await service.sendMessage("update notes for item-1 to 'New notes'");

      // Verify pending action
      expect(service.pendingActions.length, 1);
      expect(service.pendingActions.first.toolName, 'update_notes');
      expect(service.pendingActions.first.toolArgs['item_id'], 'item-1');
      
      // Verify NOT executed
      expect(service.executedActions, isEmpty);
      verifyNever(() => mockNodeService.updateNotes(any(), any()));
    });

    test('Accepting action executes and keeps in pendingActions', () async {
      // 1. Propose
      final functionCall = FunctionCall('update_notes', {'item_id': 'item-1', 'notes': 'New notes'});
      
      var callCount = 0;
      when(() => mockChatSession.sendMessage(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
             return AIResponse(text: null, functionCalls: [functionCall]);
          } else {
             return AIResponse(text: "Okay", functionCalls: []);
          }
      });
          
      await service.sendMessage("update notes for item-1 to 'New notes'");
      final action = service.pendingActions.first;

      // 2. Accept
      await service.acceptAction(action);

      // 3. Verify executed but still in pendingActions (marked as executed)
      expect(service.pendingActions.length, 1);
      expect(service.pendingActions.first.isExecuted, true);
      expect(service.executedActions.length, 1);
      expect(service.executedActions.first, action);
      
      // Verify DataService called
      verify(() => mockNodeService.updateNotes('item-1', 'New notes')).called(1);
    });

    test('Declining action removes it without executing', () async {
      // 1. Propose
      final functionCall = FunctionCall('update_notes', {'item_id': 'item-1', 'notes': 'Bad Idea'});
      
      var callCount = 0;
      when(() => mockChatSession.sendMessage(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
             return AIResponse(text: null, functionCalls: [functionCall]);
          } else {
             return AIResponse(text: "Okay", functionCalls: []);
          }
      });
          
      await service.sendMessage("update notes for item-1 to 'Bad Idea'");
      final action = service.pendingActions.first;

      // 2. Decline
      service.declineAction(action);

      // 3. Verify removed and NOT executed
      expect(service.pendingActions, isEmpty);
      expect(service.executedActions, isEmpty);
      verifyNever(() => mockNodeService.updateNotes(any(), any()));
    });
  });
}
