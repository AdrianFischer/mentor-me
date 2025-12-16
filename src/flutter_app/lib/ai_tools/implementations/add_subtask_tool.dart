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
    final taskId = args['task_id'] as String;
    final title = args['title'] as String;
    final id = dataService.addSubtask(taskId, title);
    if (id != null) {
      return {'result': 'success', 'subtask_id': id};
    } else {
      return {'result': 'error', 'message': 'Task not found'};
    }
  }
}
