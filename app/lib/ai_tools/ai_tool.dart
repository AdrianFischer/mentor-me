import '../services/node_service.dart';
import '../services/data_service.dart';

class ToolContext {
  final NodeService nodeService;
  final DataService dataService;
  ToolContext(this.nodeService, this.dataService);
}

abstract class AiTool {
  String get name;
  String get description;
  String describeAction(Map<String, dynamic> args);
  Map<String, dynamic> get inputSchema;
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, ToolContext context);
}
