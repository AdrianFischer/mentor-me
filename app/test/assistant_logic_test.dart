import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/models/ai_models.dart';

// Create Mocks for the services
class MockNodeService extends Mock implements NodeService {}
class MockDataService extends Mock implements DataService {}

void main() {
  group('AI Assistant Logic Tests', () {
    late MockNodeService mockNodeService;
    late MockDataService mockDataService;
    late ToolRegistry registry;

    setUp(() {
      mockNodeService = MockNodeService();
      mockDataService = MockDataService();
      registry = ToolRegistry(mockNodeService, mockDataService);
    });

    test('ToolRegistry describes add_project correctly', () {
      final description = registry.describeAction('add_project', {'title': 'New Project'});
      expect(description, "Create new project 'New Project'");
    });

    test('ToolRegistry describes add_task correctly', () {
      final description = registry.describeAction('add_task', {'project_id': '123', 'title': 'New Task'});
      expect(description, "Add task 'New Task' to project");
    });

    test('ToolRegistry executes add_project and calls NodeService', () async {
      // Arrange
      when(() => mockNodeService.addChild(any(), any())).thenAnswer((_) async => 'new_project_id');

      // Act
      final result = await registry.executeTool('add_project', {'title': 'New App'});

      // Assert
      expect(result['result'], 'success');
      expect(result['project_id'], 'new_project_id');
      verify(() => mockNodeService.addChild(null, 'New App')).called(1);
    });

    test('ToolRegistry executes add_task and calls NodeService', () async {
      // Arrange
      when(() => mockNodeService.addChild(any<String>(), any<String>())).thenAnswer((_) async => 'new_task_id');

      // Act
      final result = await registry.executeTool('add_task', {'project_id': 'p1', 'title': 'Fix Bug'});

      // Assert
      expect(result['result'], 'success');
      expect(result['task_id'], 'new_task_id');
      verify(() => mockNodeService.addChild('p1', 'Fix Bug')).called(1);
    });

    test('ToolRegistry executes delete_item and calls NodeService', () async {
      // Arrange
      when(() => mockNodeService.deleteNode(any())).thenReturn(null);

      // Act
      final result = await registry.executeTool('delete_item', {'item_id': 'item_1'});

      // Assert
      expect(result['result'], 'success');
      verify(() => mockNodeService.deleteNode('item_1')).called(1);
    });

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
