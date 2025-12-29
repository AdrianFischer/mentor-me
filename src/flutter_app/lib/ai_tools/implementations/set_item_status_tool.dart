import '../ai_tool.dart';
import '../../services/data_service.dart';

class SetItemStatusTool implements AiTool {
  @override
  String get name => 'set_item_status';

  @override
  String get description => 'Mark an item as active or completed';

  @override
  String describeAction(Map<String, dynamic> args) {
    final isCompleted = args['is_completed'] ?? args['isCompleted'] ?? false;
    final status = isCompleted ? 'completed' : 'active';
    return "Mark item as $status";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    print("[Tool] Executing set_item_status with args: $args");
    final itemId = args['item_id'] ?? args['itemId'];
    final isCompleted = args['is_completed'] ?? args['isCompleted'];

    if (itemId == null || isCompleted == null) {
      return {'result': 'error', 'message': 'Missing item_id or is_completed'};
    }

    dataService.setItemStatus(itemId as String, isCompleted as bool);
    return {'result': 'success'};
  }
}