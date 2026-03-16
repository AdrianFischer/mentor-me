import '../services/node_service.dart';
import '../services/data_service.dart';
import 'ai_tool.dart';
import 'implementations/save_memory_tool.dart';
import 'implementations/set_task_goal_tool.dart';
import 'implementations/record_goal_progress_tool.dart';
import 'implementations/update_notes_tool.dart';
import 'implementations/set_ai_status_tool.dart';
import 'implementations/manage_todo_images_tool.dart';
import 'implementations/upload_image_tool.dart';
import 'implementations/get_image_tool.dart';

class ToolRegistry {
  final ToolContext _context;
  final Map<String, AiTool> _tools = {};

  ToolRegistry(NodeService nodeService, DataService dataService)
      : _context = ToolContext(nodeService, dataService) {
    _register(SaveMemoryTool());
    _register(SetTaskGoalTool());
    _register(RecordGoalProgressTool());
    _register(UpdateNotesTool());
    _register(SetAiStatusTool());
    _register(ManageTodoImagesTool());
    _register(UploadImageTool());
    _register(GetImageTool());
  }

  void register(AiTool tool) {
    _register(tool);
  }

  List<AiTool> get tools => _tools.values.toList();

  void _register(AiTool tool) {
    _tools[tool.name] = tool;
  }

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
      return await tool.execute(args, _context);
    }
    return {'result': 'error', 'message': 'Tool not found'};
  }
}
