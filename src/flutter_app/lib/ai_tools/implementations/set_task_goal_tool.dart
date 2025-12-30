import '../../services/data_service.dart';
import '../../models/models.dart';
import '../ai_tool.dart';

class SetTaskGoalTool extends AiTool {
  @override
  String get name => 'set_task_goal';

  @override
  String get description => "Sets a numeric or habit goal for a specific task.";

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'task_id': {
            'type': 'string',
            'description': 'ID of the task',
          },
          'type': {
            'type': 'string',
            'enum': ['numeric', 'habit'],
            'description': 'Type of goal',
          },
          'target': {
            'type': 'number',
            'description': 'Target value',
          },
          'unit': {
            'type': 'string',
            'description': 'Unit of measurement (optional)',
          },
        },
        'required': ['task_id', 'type', 'target'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
     return "Set ${args['type']} goal for task ${args['task_id']}";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final taskId = args['task_id'] as String;
    final type = args['type'] as String;
    
    final targetVal = args['target'];
    final double target = (targetVal is num) 
        ? targetVal.toDouble() 
        : double.parse(targetVal.toString());

    final unit = args['unit'] as String?;

    TaskGoal goal;
    if (type == 'numeric') {
      goal = TaskGoal.numeric(target: target, unit: unit);
    } else {
      goal = TaskGoal.habit(targetFrequency: target);
    }

    dataService.setTaskGoal(taskId, goal);
    return {'result': 'success', 'message': "Goal set successfully for task $taskId"};
  }
}