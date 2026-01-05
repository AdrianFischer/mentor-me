import '../services/data_service.dart';
import 'ai_tool.dart';
import 'implementations/add_project_tool.dart';
import 'implementations/add_task_tool.dart';
import 'implementations/add_subtask_tool.dart';
import 'implementations/set_item_status_tool.dart';
import 'implementations/delete_item_tool.dart';
import 'implementations/save_memory_tool.dart';
import 'implementations/set_task_goal_tool.dart';
import 'implementations/record_goal_progress_tool.dart';
import 'implementations/get_project_tool.dart';
import 'implementations/get_task_tool.dart';
import 'implementations/update_item_name_tool.dart';
import 'implementations/update_notes_tool.dart';
import 'implementations/set_ai_status_tool.dart';

class ToolRegistry {
  final DataService _dataService;
  final Map<String, AiTool> _tools = {};

  ToolRegistry(this._dataService) {
    _register(AddProjectTool());
    _register(AddTaskTool());
    _register(AddSubtaskTool());
    _register(SetItemStatusTool());
    _register(DeleteItemTool());
    _register(SaveMemoryTool());
    _register(SetTaskGoalTool());
    _register(RecordGoalProgressTool());
    _register(GetProjectTool());
    _register(GetTaskTool());
    _register(UpdateItemNameTool());
    _register(UpdateNotesTool());
    _register(SetAiStatusTool());
  }

  void register(AiTool tool) {
    _register(tool);
  }

  List<AiTool> get tools => _tools.values.toList();

  void _register(AiTool tool) {
    _tools[tool.name] = tool;
  }

  /// Generates a human-readable description of what the tool will do.
  String describeAction(String name, Map<String, dynamic> args) {
    final tool = _tools[name];
    if (tool != null) {
      return tool.describeAction(args);
    }
    return "Execute $name";
  }

  Future<Map<String, dynamic>> executeTool(String name, Map<String, dynamic> args) async {
    print("[VERIFY_FLOW] Tool Execution Start: $name with args $args");
    final tool = _tools[name];
    if (tool != null) {
      return await tool.execute(args, _dataService);
    }
    return {'result': 'error', 'message': 'Tool not found'};
  }
}
