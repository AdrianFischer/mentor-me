import '../ai_tool.dart';
import '../../services/data_service.dart';

class SetItemStatusTool implements AiTool {
  @override
  String get name => 'set_item_status';

  @override
  String get description => 'Mark an item as active or completed';

  @override
  String describeAction(Map<String, dynamic> args) {
    final status = args['is_completed'] ? 'completed' : 'active';
    return "Mark item as $status";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final itemId = args['item_id'] as String;
    final isCompleted = args['is_completed'] as bool;
    dataService.setItemStatus(itemId, isCompleted);
    return {'result': 'success'};
  }
}
