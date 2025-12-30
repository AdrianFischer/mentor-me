import '../ai_tool.dart';
import '../../services/data_service.dart';

class UpdateNotesTool extends AiTool {
  @override
  String get name => 'update_notes';

  @override
  String get description => 'Updates the notes of a project, task, or subtask.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'item_id': {
            'type': 'string',
            'description': 'The UUID of the project, task, or subtask',
          },
          'notes': {
            'type': 'string',
            'description': 'The new notes content',
          },
        },
        'required': ['item_id', 'notes'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return 'Update notes for item ${args['item_id']}';
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final itemId = args['item_id'] as String?;
    final notes = args['notes'] as String?;

    if (itemId == null || notes == null) {
      return {'error': 'Missing item_id or notes'};
    }

    dataService.updateNotes(itemId, notes);
    return {'result': 'success', 'item_id': itemId};
  }
}
