import '../ai_tool.dart';
import '../../services/data_service.dart';

class DeleteItemTool implements AiTool {
  @override
  String get name => 'delete_item';

  @override
  String get description => 'Delete an item';

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Delete item";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final itemId = args['item_id'] as String;
    dataService.deleteItem(itemId);
    return {'result': 'success'};
  }
}
