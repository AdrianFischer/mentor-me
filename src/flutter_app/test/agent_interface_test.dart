import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/ai_agent.dart';
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/mcp_agent_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/services/mcp_client_service.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/services/ai_wrapper.dart';
import 'package:flutter_app/models/ai_models.dart';
import 'package:flutter_app/models/models.dart';
import 'package:firebase_ai/firebase_ai.dart';
import 'package:flutter_app/services/tts_service.dart';

// Mocks
class MockDataService extends Mock implements DataService {
  @override
  Future<List<Knowledge>> getAllKnowledge() async => [];
  @override
  List<Project> get projects => [];
  @override
  Future<List<ChatMessage>> getChatHistory(String mode, {String? conversationId}) async => [];
  @override
  Future<void> saveChatMessage(ChatMessage message, String mode) async {}
  @override
  String createConversation(String title) => 'test_conv_id';
}
class MockToolRegistry extends Mock implements ToolRegistry {}
class MockAIModelWrapper extends Mock implements AIModelWrapper {}
class MockMcpClientService extends Mock implements McpClientService {}
class MockChatSessionWrapper extends Mock implements ChatSessionWrapper {}
class MockTtsService extends Mock implements TtsService {}

void main() {
  setUpAll(() {
    registerFallbackValue(Content.text(''));
  });

  group('AiAgent Interface Tests', () {
    late MockDataService mockDataService;
    late MockToolRegistry mockToolRegistry;
    late MockAIModelWrapper mockModelWrapper;
    late MockMcpClientService mockMcpClient;
    late MockTtsService mockTtsService;

    setUp(() {
      mockDataService = MockDataService();
      mockToolRegistry = MockToolRegistry();
      mockModelWrapper = MockAIModelWrapper();
      mockMcpClient = MockMcpClientService();
      mockTtsService = MockTtsService();
      
      when(() => mockModelWrapper.startChat(history: any(named: 'history')))
          .thenReturn(MockChatSessionWrapper());
    });

    test('AssistantService implements AiAgent', () {
      final agent = AssistantService(mockDataService, mockToolRegistry, mockModelWrapper, ttsService: mockTtsService);
      expect(agent, isA<AiAgent>());
      
      expect(agent.messages, isEmpty);
      expect(agent.isLoading, isFalse);
      
      agent.setDraftMessage("Test");
      expect(agent.draftMessage, "Test");
      
      agent.toggleThinking();
      expect(agent.isThinkingMode, isTrue);
    });

    test('McpAgentService implements AiAgent', () {
      final agent = McpAgentService(mockMcpClient);
      expect(agent, isA<AiAgent>());
      
      expect(agent.messages, isEmpty);
      expect(agent.isLoading, isFalse);
      
      agent.setDraftMessage("Test");
      expect(agent.draftMessage, "Test");
      
      agent.toggleThinking();
      expect(agent.isThinkingMode, isTrue);
    });
    
    test('AssistantService sendMessage adds message', () async {
      final agent = AssistantService(mockDataService, mockToolRegistry, mockModelWrapper, ttsService: mockTtsService);
      
      // Mock chat session response
      final mockChat = MockChatSessionWrapper();
      when(() => mockModelWrapper.startChat(history: any(named: 'history'))).thenReturn(mockChat);
      when(() => mockChat.sendMessage(any())).thenAnswer((_) async => AIResponse(
        text: "Response",
        functionCalls: [],
      ));
      
      await agent.sendMessage("Hello");
      
      expect(agent.messages.length, greaterThanOrEqualTo(1));
      expect(agent.messages.any((m) => m.text == "Hello" && m.isUser), isTrue);
    });

    test('McpAgentService sendMessage adds message (simulated)', () async {
      final agent = McpAgentService(mockMcpClient);
      
      await agent.sendMessage("Hello");
      
      expect(agent.messages.length, 2); // User message + Response
      expect(agent.messages[0].text, "Hello");
      expect(agent.messages[1].text, contains("MCP Agent"));
    });
  });
}
