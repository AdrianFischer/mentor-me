import '../ai_tool.dart';

class AddProjectTool implements AiTool {
  @override
  String get name => 'add_project';

  @override
  String get description => 'Create a new project';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'title': {
            'type': 'string',
            'description': 'Title of the project',
          },
        },
        'required': ['title'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Create new project '${args['title']}'";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, ToolContext context) async {
    final title = args['title'] as String;
    final id = await context.nodeService.addChild(null, title);
    return {'result': 'success', 'project_id': id};
  }
}
