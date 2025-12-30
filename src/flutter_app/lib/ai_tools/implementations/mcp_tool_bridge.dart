import '../ai_tool.dart';
import '../../services/data_service.dart';
import '../../services/mcp_client_service.dart';

class McpToolBridge implements AiTool {
  final String _name;
  final String _description;
  final Map<String, dynamic> _parameters;
  final McpClientService _clientService;

  McpToolBridge(this._name, this._description, this._parameters, this._clientService);

  @override
  String get name => _name;

  @override
  String get description => _description;

  @override
  Map<String, dynamic> get inputSchema => _parameters;

  @override
  String describeAction(Map<String, dynamic> args) {
    return "Execute external tool '$_name' with args: $args";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    return await _clientService.executeTool(_name, args);
  }
}
