import '../ai_tool.dart';
import '../../services/data_service.dart';

class DeleteItemTool implements AiTool {
  @override
  String get name => 'delete_item';

  @override
  String get description => 'Delete an item';

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'item_id': {
            'type': 'string',
            'description': 'ID of the item',
          },
        },
        'required': ['item_id'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Delete item";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    print("[Tool] Executing delete_item with args: $args");
    final itemId = args['item_id'] ?? args['itemId'];
    
    if (itemId == null) {
      return {'result': 'error', 'message': 'Missing item_id'};
    }

    dataService.deleteItem(itemId as String);
    return {'result': 'success'};
  }
}