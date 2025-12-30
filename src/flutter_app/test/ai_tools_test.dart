import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_app/services/data_service.dart';
import 'package:flutter_app/ai_tools/implementations/add_task_tool.dart';
import 'package:flutter_app/ai_tools/implementations/add_project_tool.dart';
import 'package:flutter_app/ai_tools/implementations/add_subtask_tool.dart';
import 'package:flutter_app/ai_tools/implementations/set_item_status_tool.dart';

class MockDataService extends Mock implements DataService {}

void main() {
  late MockDataService mockDataService;

  setUp(() {
    mockDataService = MockDataService();
  });

  group('AiTools Tests', () {
    test('AddTaskTool returns task_id string, not Future', () async {
      final tool = AddTaskTool();
      final projectId = 'p1';
      final title = 'New Task';
      final newTaskId = 't1';

      when(() => mockDataService.addTask(projectId, title))
          .thenAnswer((_) async => newTaskId);

      final result = await tool.execute({
        'project_id': projectId,
        'title': title,
      }, mockDataService);

      expect(result['result'], 'success');
      // This expectation will fail if the bug exists (it will be a Future)
      expect(result['task_id'], isA<String>()); 
      expect(result['task_id'], newTaskId);
    });

    test('AddProjectTool returns project_id string', () async {
      final tool = AddProjectTool();
      final title = 'New Project';
      final newProjectId = 'p1';

      when(() => mockDataService.addProject(title))
          .thenAnswer((_) async => newProjectId);

      final result = await tool.execute({
        'title': title,
      }, mockDataService);

      expect(result['result'], 'success');
      expect(result['project_id'], isA<String>());
      expect(result['project_id'], newProjectId);
    });

    test('AddSubtaskTool returns subtask_id string', () async {
      final tool = AddSubtaskTool();
      final taskId = 't1';
      final title = 'New Subtask';
      final newSubtaskId = 's1';

      when(() => mockDataService.addSubtask(taskId, title))
          .thenAnswer((_) async => newSubtaskId);

      final result = await tool.execute({
        'task_id': taskId,
        'title': title,
      }, mockDataService);

      expect(result['result'], 'success');
      expect(result['subtask_id'], isA<String>());
      expect(result['subtask_id'], newSubtaskId);
    });
    
    test('SetItemStatusTool awaits the operation', () async {
      final tool = SetItemStatusTool();
      final itemId = 'i1';
      final isCompleted = true;
      
      // We can't easily test "await" without a delay in mock, 
      // but we can ensure it calls the service.
      when(() => mockDataService.setItemStatus(itemId, isCompleted))
          .thenAnswer((_) async => {}); // Return Future<void>

      final result = await tool.execute({
        'item_id': itemId,
        'is_completed': isCompleted,
      }, mockDataService);
      
      expect(result['result'], 'success');
      verify(() => mockDataService.setItemStatus(itemId, isCompleted)).called(1);
    });
  });
}
