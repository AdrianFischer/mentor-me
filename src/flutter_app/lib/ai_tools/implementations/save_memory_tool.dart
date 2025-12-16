import '../ai_tool.dart';
import '../../services/data_service.dart';

class SaveMemoryTool implements AiTool {
  @override
  String get name => 'save_memory';

  @override
  String get description => 'Saves a fact or insight to the Knowledge Base.';

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Remember: ${args['fact']}";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final fact = args['fact'] as String;
    await dataService.saveKnowledge(fact);
    return {'result': 'success', 'message': 'Memory saved.'};
  }
}
