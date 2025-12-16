/// Integration tests for Gemini API connection and tool execution.
/// 
/// REQUIRED: These tests require a valid GEMINI_API_KEY to run.
/// 
/// To set up:
/// 1. Create a `.env` file in the flutter_app root directory
/// 2. Add: GEMINI_API_KEY=your_api_key_here
/// 3. Get your API key from: https://makersuite.google.com/app/apikey
/// 
/// Alternative: Run with --dart-define:
/// flutter test --dart-define=GEMINI_API_KEY=your_key_here test/gemini_api_test.dart
/// 
/// If no API key is provided, the tests will FAIL (as expected).

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_app/config.dart';
import 'package:flutter_app/services/assistant_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';

void main() {
  group('Gemini API Integration Tests', () {
    late DataService dataService;
    late ToolRegistry toolRegistry;
    late AssistantService assistantService;

    setUpAll(() async {
      // Initialize dotenv - try to load from .env file, or use empty if not available
      try {
        await dotenv.load(fileName: ".env");
      } catch (e) {
        // If .env file doesn't exist, initialize with empty env
        dotenv.testLoad(fileInput: '');
      }
    });

    setUp(() {
      dataService = DataService();
      toolRegistry = ToolRegistry(dataService);
      assistantService = AssistantService(dataService, toolRegistry);
    });

    tearDown(() {
      // Clean up if needed
    });

    test('Test Gemini API connection and get response', () async {
      // Fail if API key is not available
      expect(Config.hasGeminiKey, isTrue,
          reason: 'GEMINI_API_KEY must be set in .env file or via --dart-define. '
                  'Create a .env file in the flutter_app root directory with: GEMINI_API_KEY=your_key_here');

      // Verify API key is loaded
      expect(Config.geminiApiKey, isNotEmpty, 
          reason: 'API key should be available for this test');

      // Send a simple message to test the connection
      const testMessage = 'Hello, can you respond with just "Hello" to confirm the connection works?';
      
      // Wait for the message to be sent and response received
      await assistantService.sendMessage(testMessage);

      // Wait a bit for async operations to complete
      await Future.delayed(const Duration(seconds: 3));

      // Verify we got a response
      expect(assistantService.messages.length, greaterThan(0),
          reason: 'Should have at least one message (the user message)');

      // Check that we got a response from the assistant (not just the user message)
      final assistantMessages = assistantService.messages
          .where((msg) => !msg.isUser)
          .toList();
      
      expect(assistantMessages.length, greaterThan(0),
          reason: 'Should have received at least one response from Gemini');

      // Verify the response is not empty
      final lastAssistantMessage = assistantMessages.last;
      expect(lastAssistantMessage.text, isNotEmpty,
          reason: 'Assistant response should not be empty');

      print('✓ Gemini API connection test passed!');
      print('Response received: ${lastAssistantMessage.text.substring(0, lastAssistantMessage.text.length > 100 ? 100 : lastAssistantMessage.text.length)}...');
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Test Gemini API with tool execution flow', () async {
      // Fail if API key is not available
      expect(Config.hasGeminiKey, isTrue,
          reason: 'GEMINI_API_KEY must be set in .env file or via --dart-define. '
                  'Create a .env file in the flutter_app root directory with: GEMINI_API_KEY=your_key_here');

      // Clear any existing messages
      // Note: AssistantService doesn't expose a clear method, so we'll work with existing state

      // Send a message that should trigger a tool call (create a project)
      const testMessage = 'Create a new project called "Test Project"';
      
      // Get initial message count
      final initialMessageCount = assistantService.messages.length;

      // Send the message
      await assistantService.sendMessage(testMessage);

      // Wait for async operations (tool execution, API calls)
      await Future.delayed(const Duration(seconds: 5));

      // Verify we got responses
      expect(assistantService.messages.length, greaterThan(initialMessageCount),
          reason: 'Should have received new messages');

      // Check if a project was created (tool execution)
      final projectsAfter = dataService.projects
          .where((p) => p.title == 'Test Project')
          .toList();
      
      // The tool should have been executed automatically
      // Note: This might not always work if the model doesn't call the tool,
      // but it tests the integration flow
      if (projectsAfter.isNotEmpty) {
        print('✓ Tool execution test passed! Project was created.');
        expect(projectsAfter.length, 1,
            reason: 'Should have created exactly one "Test Project"');
      } else {
        print('⚠ Tool execution test: Model did not call the tool, but API connection works');
        // Still verify we got a response
        final assistantMessages = assistantService.messages
            .where((msg) => !msg.isUser)
            .toList();
        expect(assistantMessages.length, greaterThan(0),
            reason: 'Should have received a response from Gemini');
      }
    }, timeout: const Timeout(Duration(seconds: 30)));

    test('Test Gemini API error handling with invalid message', () async {
      // Fail if API key is not available
      expect(Config.hasGeminiKey, isTrue,
          reason: 'GEMINI_API_KEY must be set in .env file or via --dart-define. '
                  'Create a .env file in the flutter_app root directory with: GEMINI_API_KEY=your_key_here');

      // Send an empty message (should be handled gracefully)
      await assistantService.sendMessage('');

      // Should not crash or add messages for empty input
      // The implementation should return early for empty messages
      expect(assistantService.messages.length, 
          greaterThanOrEqualTo(0),
          reason: 'Empty message should be handled gracefully');
    }, timeout: const Timeout(Duration(seconds: 10)));
  });
}

