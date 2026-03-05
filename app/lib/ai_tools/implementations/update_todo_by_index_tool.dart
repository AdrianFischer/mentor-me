import '../ai_tool.dart';
import '../../services/data_service.dart';

class UpdateTodoByIndexTool implements AiTool {
  @override
  String get name => 'update_todo_by_index';

  @override
  String get description => 'Updates a task or subtask using its index from the last list call.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'index': {
            'type': 'integer',
            'description': 'The 1-based index of the item.',
          },
          'new_title': { 'type': 'string' },
          'notes': { 'type': 'string' },
          'is_completed': { 'type': 'boolean' }
        },
        'required': ['index'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Updating todo at index ${args['index']}";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final index = args['index'] as int?;
    if (index == null) return {'result': 'error', 'message': 'Missing index'};

    final itemId = dataService.getIdFromSessionIndex(index);
    if (itemId == null) return {'result': 'error', 'message': 'Invalid index: $index'};

    if (args.containsKey('new_title')) {
      dataService.updateTitle(itemId, args['new_title'] as String);
    }
    if (args.containsKey('notes')) {
      dataService.updateNotes(itemId, args['notes'] as String);
    }
    if (args.containsKey('is_completed')) {
      await dataService.setItemStatus(itemId, args['is_completed'] as bool);
    }

    return {'result': 'success', 'item_id': itemId};
  }
}
