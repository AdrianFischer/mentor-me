import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter/services.dart';
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/models/models.dart';

class MockDataService extends Mock implements DataService {
  @override
  List<Project> get projects => [];
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

    setUp(() {
      mockDataService = MockDataService();
      // Stub history and knowledge
      when(() => mockDataService.getChatHistory(any())).thenAnswer((_) async => []);
      when(() => mockDataService.saveChatMessage(any(), any())).thenAnswer((_) async {});
      when(() => mockDataService.clearChatHistory(any())).thenAnswer((_) async {});
      when(() => mockDataService.getAllKnowledge()).thenAnswer((_) async => []);
      
      // Stub tool execution (add_project)
      when(() => mockDataService.addProject(any())).thenReturn('proj_id');

      registry = ToolRegistry(mockDataService);
      service = AssistantService(mockDataService, registry);
    });

    test('Modification request adds to pendingActions instead of executing', () async {
      expect(service.pendingActions, isEmpty);
      expect(service.executedActions, isEmpty);

      // Send a request that triggers "add_project" in Mock Mode
      await service.sendMessage("create a new project 'Review Me'");

      // Verify pending action
      expect(service.pendingActions.length, 1);
      expect(service.pendingActions.first.toolName, 'add_project');
      expect(service.pendingActions.first.toolArgs['title'], 'Review Me');
      
      // Verify NOT executed
      expect(service.executedActions, isEmpty);
      verifyNever(() => mockDataService.addProject(any()));
    });

    test('Accepting action executes and moves to history', () async {
      // 1. Propose
      await service.sendMessage("create a new project 'Review Me'");
      final action = service.pendingActions.first;

      // 2. Accept
      await service.acceptAction(action);

      // 3. Verify executed
      expect(service.pendingActions, isEmpty);
      expect(service.executedActions.length, 1);
      expect(service.executedActions.first, action);
      
      // Verify DataService called
      verify(() => mockDataService.addProject('Review Me')).called(1);
    });

    test('Declining action removes it without executing', () async {
      // 1. Propose
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
