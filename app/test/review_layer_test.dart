import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/ai_wrapper.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/models/models.dart';
import 'package:firebase_ai/firebase_ai.dart';

class MockDataService extends Mock implements DataService {
  @override
  List<Project> get projects => [];
}

class MockAIModelWrapper extends Mock implements AIModelWrapper {}
class MockChatSessionWrapper extends Mock implements ChatSessionWrapper {}

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

    setUp(() {
      mockDataService = MockDataService();
      mockModelWrapper = MockAIModelWrapper();
      mockChatSession = MockChatSessionWrapper();

      // Stub history and knowledge
      when(() => mockDataService.getChatHistory(any())).thenAnswer((_) async => []);
      when(() => mockDataService.saveChatMessage(any(), any())).thenAnswer((_) async {});
      when(() => mockDataService.clearChatHistory(any())).thenAnswer((_) async {});
      when(() => mockDataService.getAllKnowledge()).thenAnswer((_) async => []);
      
      // Stub tool execution (add_project)
      when(() => mockDataService.addProject(any())).thenAnswer((_) async => 'proj_id');

      // Stub Wrapper
      when(() => mockModelWrapper.startChat(history: any(named: 'history'))).thenReturn(mockChatSession);
      when(() => mockChatSession.history).thenReturn([]);

      registry = ToolRegistry(mockDataService);
      service = AssistantService(mockDataService, registry, mockModelWrapper);
    });

    test('Modification request adds to pendingActions instead of executing', () async {
      // Mock response with function call
      final functionCall = FunctionCall('add_project', {'title': 'Review Me'});
      
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

      // Send a request that triggers "add_project"
      await service.sendMessage("create a new project 'Review Me'");

      // Verify pending action
      expect(service.pendingActions.length, 1);
      expect(service.pendingActions.first.toolName, 'add_project');
      expect(service.pendingActions.first.toolArgs['title'], 'Review Me');
      
      // Verify NOT executed
      expect(service.executedActions, isEmpty);
      verifyNever(() => mockDataService.addProject(any()));
    });

    test('Accepting action executes and keeps in pendingActions', () async {
      // 1. Propose
      final functionCall = FunctionCall('add_project', {'title': 'Review Me'});
      
      var callCount = 0;
      when(() => mockChatSession.sendMessage(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
             return AIResponse(text: null, functionCalls: [functionCall]);
          } else {
             return AIResponse(text: "Okay", functionCalls: []);
          }
      });
          
      await service.sendMessage("create a new project 'Review Me'");
      final action = service.pendingActions.first;

      // 2. Accept
      await service.acceptAction(action);

      // 3. Verify executed but still in pendingActions (marked as executed)
      expect(service.pendingActions.length, 1);
      expect(service.pendingActions.first.isExecuted, true);
      expect(service.executedActions.length, 1);
      expect(service.executedActions.first, action);
      
      // Verify DataService called
      verify(() => mockDataService.addProject('Review Me')).called(1);
    });

    test('Declining action removes it without executing', () async {
      // 1. Propose
      final functionCall = FunctionCall('add_project', {'title': 'Bad Idea'});
      
      var callCount = 0;
      when(() => mockChatSession.sendMessage(any())).thenAnswer((_) async {
          callCount++;
          if (callCount == 1) {
             return AIResponse(text: null, functionCalls: [functionCall]);
          } else {
             return AIResponse(text: "Okay", functionCalls: []);
          }
      });
          
      await service.sendMessage("create a new project 'Bad Idea'");
      final action = service.pendingActions.first;

      // 2. Decline
      service.declineAction(action);

      // 3. Verify removed and NOT executed
      expect(service.pendingActions, isEmpty);
      expect(service.executedActions, isEmpty);
      verifyNever(() => mockDataService.addProject(any()));
    });
  });
}
