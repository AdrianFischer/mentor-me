import '../ai_tool.dart';
import '../../services/data_service.dart';

class ManageTodoImagesTool implements AiTool {
  @override
  String get name => 'manage_todo_images';

  @override
  String get description => 'Adds or removes local image paths for a task or subtask using its index.';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'index': { 'type': 'integer', 'description': 'The index from the last list call.' },
          'action': { 'type': 'string', 'enum': ['add', 'remove'] },
          'file_path': { 'type': 'string', 'description': 'The absolute local path to the image file.' }
        },
        'required': ['index', 'action', 'file_path'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return "${args['action']} image ${args['file_path']} to index ${args['index']}";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final index = args['index'] as int?;
    final action = args['action'] as String?;
    final filePath = args['file_path'] as String?;

    if (index == null || action == null || filePath == null) {
      return {'result': 'error', 'message': 'Missing index, action, or file_path'};
    }

    final itemId = dataService.getIdFromSessionIndex(index);
    if (itemId == null) return {'result': 'error', 'message': 'Invalid index: $index'};

    if (action == 'add') {
      await dataService.addLocalImagePath(itemId, filePath);
    } else if (action == 'remove') {
      await dataService.removeLocalImagePath(itemId, filePath);
    }

    return {'result': 'success', 'item_id': itemId};
  }
}
