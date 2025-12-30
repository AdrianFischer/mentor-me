import '../services/data_service.dart';

abstract class AiTool {
  /// The unique name of the tool (e.g., 'add_project').
  String get name;

  /// A human-readable description of what the tool does.
  String get description;

  /// Returns a human-readable string describing the action for a specific set of arguments.
  String describeAction(Map<String, dynamic> args);

  /// Returns the JSON Schema for the tool's input arguments.
  /// This is used for both internal AI tool definition and MCP server registration.
  Map<String, dynamic> get inputSchema;

  /// Executes the tool with the given arguments.
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService);
}
