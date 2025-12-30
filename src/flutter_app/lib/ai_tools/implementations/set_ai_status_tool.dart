import '../ai_tool.dart';
import '../../services/data_service.dart';
import '../../models/models.dart';

class SetAiStatusTool extends AiTool {
  @override
  String get name => 'set_ai_status';

  @override
  String get description => 'Sets the AI agent status for a task or subtask. Status can be: notReady, ready, inProgress, or done. When status is set to "done", the item is automatically marked as completed.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'item_id': {
            'type': 'string',
            'description': 'The UUID of the task or subtask',
          },
          'status': {
            'type': 'string',
            'enum': ['notReady', 'ready', 'inProgress', 'done'],
            'description': 'The AI agent status: notReady (paused), ready (ready for agent), inProgress (agent working), or done (completed by agent)',
          },
        },
        'required': ['item_id', 'status'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return 'Set AI status for item ${args['item_id']} to ${args['status']}';
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final itemId = args['item_id'] as String?;
    final statusStr = args['status'] as String?;

    if (itemId == null || statusStr == null) {
      return {'error': 'Missing item_id or status'};
    }

    // Convert string to enum
    AiStatus status;
    switch (statusStr) {
      case 'notReady':
        status = AiStatus.notReady;
        break;
      case 'ready':
        status = AiStatus.ready;
        break;
      case 'inProgress':
        status = AiStatus.inProgress;
        break;
      case 'done':
        status = AiStatus.done;
        break;
      default:
        return {'error': 'Invalid status. Must be one of: notReady, ready, inProgress, done'};
    }

    await dataService.setAiStatus(itemId, status);
    return {'result': 'success', 'item_id': itemId, 'status': statusStr};
  }
}

