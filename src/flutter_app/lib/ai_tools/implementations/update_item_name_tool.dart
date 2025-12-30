import '../ai_tool.dart';
import '../../services/data_service.dart';

class UpdateItemNameTool extends AiTool {
  @override
  String get name => 'update_item_name';

  @override
  String get description => 'Updates the name (title) of a project, task, or subtask.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'item_id': {
            'type': 'string',
            'description': 'The UUID of the project, task, or subtask',
          },
          'new_name': {
            'type': 'string',
            'description': 'The new name/title for the item',
          },
        },
        'required': ['item_id', 'new_name'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return 'Rename item ${args['item_id']} to "${args['new_name']}"';
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final itemId = args['item_id'] as String?;
    final newName = args['new_name'] as String?;

    if (itemId == null || newName == null) {
      return {'error': 'Missing item_id or new_name'};
    }

    dataService.updateTitle(itemId, newName);
    return {'result': 'success', 'item_id': itemId, 'new_name': newName};
  }
}
