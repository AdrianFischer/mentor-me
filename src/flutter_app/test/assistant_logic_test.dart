import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/ai_tools/tool_registry.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/models/ai_models.dart';

// Create a Mock for the DataService
class MockDataService extends Mock implements DataService {}

void main() {
  group('AI Assistant Logic Tests', () {
    late MockDataService mockDataService;
    late ToolRegistry registry;

    setUp(() {
      mockDataService = MockDataService();
      registry = ToolRegistry(mockDataService);
    });

    test('ToolRegistry describes add_project correctly', () {
      final description = registry.describeAction('add_project', {'title': 'New Project'});
      expect(description, "Create new project 'New Project'");
    });

    test('ToolRegistry describes add_task correctly', () {
      final description = registry.describeAction('add_task', {'project_id': '123', 'title': 'New Task'});
      expect(description, "Add task 'New Task' to project");
    });

    test('ToolRegistry executes add_project and calls DataService', () async {
      // Arrange
      when(() => mockDataService.addProject(any())).thenAnswer((_) async => 'new_project_id');

      // Act
      final result = await registry.executeTool('add_project', {'title': 'New App'});

      // Assert
      expect(result['result'], 'success');
      expect(result['project_id'], 'new_project_id');
      verify(() => mockDataService.addProject('New App')).called(1);
    });

    test('ToolRegistry executes add_task and calls DataService', () async {
      // Arrange
      when(() => mockDataService.addTask(any(), any())).thenAnswer((_) async => 'new_task_id');

      // Act
      final result = await registry.executeTool('add_task', {'project_id': 'p1', 'title': 'Fix Bug'});

      // Assert
      expect(result['result'], 'success');
      expect(result['task_id'], 'new_task_id');
      verify(() => mockDataService.addTask('p1', 'Fix Bug')).called(1);
    });

    test('ToolRegistry executes delete_item and calls DataService', () async {
      // Arrange
      // deleteItem returns void, so strictly speaking we don't need a return value, 
      // but DataService.deleteItem is void. Mocktail handles void automatically mostly, 
      // or we just don't set a return.
      // However, usually good to stub to ensure no errors.
      // Since it returns void, we don't need `thenReturn`.
      
      // Act
      final result = await registry.executeTool('delete_item', {'item_id': 'item_1'});

      // Assert
      expect(result['result'], 'success');
      verify(() => mockDataService.deleteItem('item_1')).called(1);
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




