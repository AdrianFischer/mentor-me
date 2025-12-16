import '../services/data_service.dart';

class ToolRegistry {
  final DataService _dataService;

  ToolRegistry(this._dataService);

  /// Generates a human-readable description of what the tool will do.
  String describeAction(String name, Map<String, dynamic> args) {
    switch (name) {
      case 'add_project':
        return "Create new project '${args['title']}'";
      case 'add_task':
        // Ideally we would look up the project name here, but for simplicity:
        return "Add task '${args['title']}' to project";
      case 'add_subtask':
        return "Add subtask '${args['title']}'";
      case 'set_item_status':
        final status = args['is_completed'] ? 'completed' : 'active';
        return "Mark item as $status";
      case 'delete_item':
        return "Delete item";
      default:
        return "Execute $name";
    }
  }

  Future<Map<String, dynamic>> executeTool(String name, Map<String, dynamic> args) async {
    print("[VERIFY_FLOW] Tool Execution Start: $name with args $args");
    switch (name) {
      case 'add_project':
        final title = args['title'] as String;
        final id = _dataService.addProject(title);
        return {'result': 'success', 'project_id': id};
      
      case 'add_task':
        final projectId = args['project_id'] as String;
        final title = args['title'] as String;
        final id = _dataService.addTask(projectId, title);
        if (id != null) {
          return {'result': 'success', 'task_id': id};
        } else {
          return {'result': 'error', 'message': 'Project not found'};
        }

      case 'add_subtask':
        final taskId = args['task_id'] as String;
        final title = args['title'] as String;
        final id = _dataService.addSubtask(taskId, title);
        if (id != null) {
          return {'result': 'success', 'subtask_id': id};
        } else {
          return {'result': 'error', 'message': 'Task not found'};
        }

      case 'set_item_status':
        final itemId = args['item_id'] as String;
        final isCompleted = args['is_completed'] as bool;
        _dataService.setItemStatus(itemId, isCompleted);
        return {'result': 'success'};

      case 'delete_item':
        final itemId = args['item_id'] as String;
        _dataService.deleteItem(itemId);
        return {'result': 'success'};

      default:
        return {'result': 'error', 'message': 'Tool not found'};
    }
  }
}
