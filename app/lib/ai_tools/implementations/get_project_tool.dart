import '../ai_tool.dart';
import '../../services/data_service.dart';

class GetProjectTool extends AiTool {
  @override
  String get name => 'get_project';

  @override
  String get description => 'Retrieves details of a specific project, including its tasks.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'project_id': {
            'type': 'string',
            'description': 'The UUID of the project',
          },
        },
        'required': ['project_id'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return 'Get details for project ID: ${args['project_id']}';
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final projectId = args['project_id'] as String?;
    if (projectId == null) {
      return {'error': 'Missing project_id'};
    }

    try {
      final project = dataService.projects.firstWhere(
        (p) => p.id == projectId,
        orElse: () => throw Exception('Project not found'),
      );
      return project.toJson();
    } catch (e) {
      return {'error': 'Project not found: $projectId'};
    }
  }
}
