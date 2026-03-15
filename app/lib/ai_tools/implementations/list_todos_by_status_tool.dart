import '../ai_tool.dart';
import '../../models/node.dart';

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
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, ToolContext context) async {
    final status = args['status'] as String?;
    if (status == null) {
      return {'result': 'error', 'message': 'Missing status'};
    }

    final isCompletedTarget = status == 'completed';
    final results = <Map<String, dynamic>>[];
    context.dataService.clearSessionIndex();

    void collectNodes(Node node, String? projectTitle) {
      for (final child in node.children) {
        if (child.isCompleted == isCompletedTarget) {
          final index = context.dataService.addToSessionIndex(child.id);
          results.add({
            'index': index,
            'id': child.id,
            'title': child.title,
            'type': child.children.isEmpty ? 'leaf' : 'node',
            'project': projectTitle ?? node.title,
            'notes': child.notes,
            'images': child.localImagePaths,
          });
        }
        collectNodes(child, projectTitle ?? node.title);
      }
    }

    for (final root in context.nodeService.rootNodes) {
      collectNodes(root, root.title);
    }

    return {'result': 'success', 'items': results};
  }
}
