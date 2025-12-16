import '../services/data_service.dart';

abstract class AiTool {
  /// The unique name of the tool (e.g., 'add_project').
  String get name;

  /// A human-readable description of what the tool does.
  String get description;

  /// Returns a human-readable string describing the action for a specific set of arguments.
  String describeAction(Map<String, dynamic> args);

  /// Executes the tool with the given arguments.
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService);
}
