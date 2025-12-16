import '../ai_tool.dart';
import '../../services/data_service.dart';

class AddProjectTool implements AiTool {
  @override
  String get name => 'add_project';

  @override
  String get description => 'Create a new project';

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Create new project '${args['title']}'";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final title = args['title'] as String;
    final id = dataService.addProject(title);
    return {'result': 'success', 'project_id': id};
  }
}
