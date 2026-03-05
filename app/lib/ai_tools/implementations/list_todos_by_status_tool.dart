import '../ai_tool.dart';
import '../../services/data_service.dart';

class ListTodosByStatusTool implements AiTool {
  @override
  String get name => 'list_todos_by_status';

  @override
  String get description => 'Lists tasks and subtasks by status with an index for easier referencing.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'status': {
            'type': 'string',
            'enum': ['active', 'completed'],
            'description': 'The status of items to list.',
          },
        },
        'required': ['status'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Listing ${args['status']} todos";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final status = args['status'] as String?;
    if (status == null) {
      return {'result': 'error', 'message': 'Missing status'};
    }

    final isCompletedTarget = status == 'completed';
    final results = <Map<String, dynamic>>[];
    dataService.clearSessionIndex();

    for (final project in dataService.projects) {
      for (final task in project.tasks) {
        if (task.isCompleted == isCompletedTarget) {
          final index = dataService.addToSessionIndex(task.id);
          results.add({
            'index': index,
            'id': task.id,
            'title': task.title,
            'type': 'task',
            'project': project.title,
            'notes': task.notes,
            'images': task.localImagePaths,
          });
        }
        for (final subtask in task.subtasks) {
          if (subtask.isCompleted == isCompletedTarget) {
            final index = dataService.addToSessionIndex(subtask.id);
            results.add({
              'index': index,
              'id': subtask.id,
              'title': subtask.title,
              'type': 'subtask',
              'parent_task': task.title,
              'project': project.title,
              'notes': subtask.notes,
              'images': subtask.localImagePaths,
            });
          }
        }
      }
    }

    return {'result': 'success', 'items': results};
  }
}
