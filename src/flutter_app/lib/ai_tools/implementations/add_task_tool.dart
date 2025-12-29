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
    print("[Tool] Executing add_task with args: $args");
    final projectId = args['project_id'] ?? args['projectId'];
    final title = args['title'];

    if (projectId == null || title == null) {
       return {'result': 'error', 'message': 'Missing project_id or title'};
    }

    final id = dataService.addTask(projectId as String, title as String);
    if (id != null) {
      return {'result': 'success', 'task_id': id};
    } else {
      return {'result': 'error', 'message': 'Project not found with ID: $projectId'};
    }
  }
}