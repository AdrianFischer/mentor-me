import '../ai_tool.dart';

class GetTaskTool extends AiTool {
  @override
  String get name => 'get_task';

  @override
  String get description => 'Retrieves details of a specific task, including its subtasks.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'task_id': {
            'type': 'string',
            'description': 'The UUID of the task',
          },
        },
        'required': ['task_id'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return 'Get details for task ID: ${args['task_id']}';
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, ToolContext context) async {
    final taskId = args['task_id'] as String?;
    if (taskId == null) {
      return {'error': 'Missing task_id'};
    }

    final node = context.nodeService.findNode(taskId);
    if (node == null) {
      return {'error': 'Task not found: $taskId'};
    }
    return node.toJson();
  }
}
