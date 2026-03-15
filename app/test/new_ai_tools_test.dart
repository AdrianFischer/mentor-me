import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/models/node.dart';
import 'package:flutter_app/ai_tools/ai_tool.dart';
import 'package:flutter_app/ai_tools/implementations/get_project_tool.dart';
import 'package:flutter_app/ai_tools/implementations/get_task_tool.dart';
import 'package:flutter_app/ai_tools/implementations/update_item_name_tool.dart';

class MockNodeService extends Mock implements NodeService {}
class MockDataService extends Mock implements DataService {}

void main() {
  late MockNodeService mockNodeService;
  late MockDataService mockDataService;
  late ToolContext toolContext;

  late Node testProject;

  setUp(() {
    mockNodeService = MockNodeService();
    mockDataService = MockDataService();
    toolContext = ToolContext(mockNodeService, mockDataService);

    testProject = Node(
      id: 'project-1',
      title: 'Test Project',
      children: [
        Node(
          id: 'task-1',
          title: 'Test Task',
          parentId: 'project-1',
          children: [
            Node(id: 'subtask-1', title: 'Subtask 1', parentId: 'task-1'),
          ],
        ),
      ],
    );
  });

  group('New AI Tools Tests', () {
    test('GetProjectTool returns node json', () async {
      final tool = GetProjectTool();
      when(() => mockNodeService.findNode('project-1')).thenReturn(testProject);

      final result = await tool.execute({'project_id': 'project-1'}, toolContext);

      expect(result['id'], 'project-1');
      expect(result['title'], 'Test Project');
      expect((result['children'] as List).length, 1);
    });

    test('GetTaskTool returns node json', () async {
      final tool = GetTaskTool();
      final testTask = testProject.children.first;
      when(() => mockNodeService.findNode('task-1')).thenReturn(testTask);

      final result = await tool.execute({'task_id': 'task-1'}, toolContext);

      expect(result['id'], 'task-1');
      expect(result['title'], 'Test Task');
      expect((result['children'] as List).length, 1);
    });

    test('UpdateItemNameTool calls updateTitle', () async {
      final tool = UpdateItemNameTool();
      when(() => mockNodeService.updateTitle(any(), any())).thenReturn(null);

      final result = await tool.execute({
        'item_id': 'item-1',
        'new_name': 'New Name',
      }, toolContext);

      expect(result['result'], 'success');
      verify(() => mockNodeService.updateTitle('item-1', 'New Name')).called(1);
    });
  });
}
