import '../ai_tool.dart';
import '../../services/data_service.dart';

class AddSubtaskTool implements AiTool {
  @override
  String get name => 'add_subtask';

  @override
  String get description => 'Add a subtask to a task';

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Add subtask '${args['title']}'";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    print("[Tool] Executing add_subtask with args: $args");
    final taskId = args['task_id'] ?? args['taskId'];
    final title = args['title'];

    if (taskId == null || title == null) {
      return {'result': 'error', 'message': 'Missing task_id or title'};
    }

    final id = dataService.addSubtask(taskId as String, title as String);
    if (id != null) {
      return {'result': 'success', 'subtask_id': id};
    } else {
      return {'result': 'error', 'message': 'Task not found with ID: $taskId'};
    }
  }
}