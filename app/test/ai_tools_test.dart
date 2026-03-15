import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/node_service.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/ai_tools/ai_tool.dart';
import 'package:flutter_app/ai_tools/implementations/add_task_tool.dart';
import 'package:flutter_app/ai_tools/implementations/add_project_tool.dart';
import 'package:flutter_app/ai_tools/implementations/add_subtask_tool.dart';
import 'package:flutter_app/ai_tools/implementations/set_item_status_tool.dart';

class MockNodeService extends Mock implements NodeService {}
class MockDataService extends Mock implements DataService {}

void main() {
  late MockNodeService mockNodeService;
  late MockDataService mockDataService;
  late ToolContext toolContext;

  setUp(() {
    mockNodeService = MockNodeService();
    mockDataService = MockDataService();
    toolContext = ToolContext(mockNodeService, mockDataService);
  });

  group('AiTools Tests', () {
    test('AddTaskTool returns task_id string, not Future', () async {
      final tool = AddTaskTool();
      final projectId = 'p1';
      final title = 'New Task';
      final newTaskId = 't1';

      when(() => mockNodeService.addChild(projectId, title))
          .thenAnswer((_) async => newTaskId);

      final result = await tool.execute({
        'project_id': projectId,
        'title': title,
      }, toolContext);

      expect(result['result'], 'success');
      expect(result['task_id'], isA<String>());
      expect(result['task_id'], newTaskId);
    });

    test('AddProjectTool returns project_id string', () async {
      final tool = AddProjectTool();
      final title = 'New Project';
      final newProjectId = 'p1';

      when(() => mockNodeService.addChild(null, title))
          .thenAnswer((_) async => newProjectId);

      final result = await tool.execute({
        'title': title,
      }, toolContext);

      expect(result['result'], 'success');
      expect(result['project_id'], isA<String>());
      expect(result['project_id'], newProjectId);
    });

    test('AddSubtaskTool returns subtask_id string', () async {
      final tool = AddSubtaskTool();
      final taskId = 't1';
      final title = 'New Subtask';
      final newSubtaskId = 's1';

      when(() => mockNodeService.addChild(taskId, title))
          .thenAnswer((_) async => newSubtaskId);

      final result = await tool.execute({
        'task_id': taskId,
        'title': title,
      }, toolContext);

      expect(result['result'], 'success');
      expect(result['subtask_id'], isA<String>());
      expect(result['subtask_id'], newSubtaskId);
    });

    test('SetItemStatusTool awaits the operation', () async {
      final tool = SetItemStatusTool();
      final itemId = 'i1';
      final isCompleted = true;

      when(() => mockNodeService.setNodeStatus(itemId, isCompleted))
          .thenAnswer((_) async => {});

      final result = await tool.execute({
        'item_id': itemId,
        'is_completed': isCompleted,
      }, toolContext);

      expect(result['result'], 'success');
      verify(() => mockNodeService.setNodeStatus(itemId, isCompleted)).called(1);
    });
  });
}
