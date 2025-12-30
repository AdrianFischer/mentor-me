import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/models/models.dart';
import 'package:flutter_app/ai_tools/implementations/get_project_tool.dart';
import 'package:flutter_app/ai_tools/implementations/get_task_tool.dart';
import 'package:flutter_app/ai_tools/implementations/update_item_name_tool.dart';

class MockDataService extends Mock implements DataService {}

void main() {
  late MockDataService mockDataService;
  late Project testProject;
  late Task testTask;

  setUp(() {
    mockDataService = MockDataService();
    
    testTask = const Task(
      id: 'task-1',
      title: 'Test Task',
      subtasks: [Subtask(id: 'subtask-1', title: 'Subtask 1')],
    );
    
    testProject = Project(
      id: 'project-1',
      title: 'Test Project',
      tasks: [testTask],
    );
  });

  group('New AI Tools Tests', () {
    test('GetProjectTool returns project json', () async {
      final tool = GetProjectTool();
      when(() => mockDataService.projects).thenReturn([testProject]);

      final result = await tool.execute({'project_id': 'project-1'}, mockDataService);

      expect(result['id'], 'project-1');
      expect(result['title'], 'Test Project');
      expect((result['tasks'] as List).length, 1);
    });

    test('GetTaskTool returns task json', () async {
      final tool = GetTaskTool();
      when(() => mockDataService.projects).thenReturn([testProject]);

      final result = await tool.execute({'task_id': 'task-1'}, mockDataService);

      expect(result['id'], 'task-1');
      expect(result['title'], 'Test Task');
      expect((result['subtasks'] as List).length, 1);
    });

    test('UpdateItemNameTool calls updateTitle', () async {
      final tool = UpdateItemNameTool();
      // updateTitle is void, so we verify the call
      when(() => mockDataService.updateTitle(any(), any())).thenReturn(null);

      final result = await tool.execute({
        'item_id': 'item-1',
        'new_name': 'New Name',
      }, mockDataService);

      expect(result['result'], 'success');
      verify(() => mockDataService.updateTitle('item-1', 'New Name')).called(1);
    });
  });
}
