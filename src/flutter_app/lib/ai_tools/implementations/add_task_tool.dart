import '../ai_tool.dart';
import '../../services/data_service.dart';

class AddTaskTool implements AiTool {
  @override
  String get name => 'add_task';

  @override
  String get description => 'Add a task to a project';

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Add task '${args['title']}' to project";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final projectId = args['project_id'] as String;
    final title = args['title'] as String;
    final id = dataService.addTask(projectId, title);
    if (id != null) {
      return {'result': 'success', 'task_id': id};
    } else {
      return {'result': 'error', 'message': 'Project not found'};
    }
  }
}
