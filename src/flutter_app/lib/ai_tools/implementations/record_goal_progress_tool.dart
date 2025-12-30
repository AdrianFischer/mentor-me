import '../../services/data_service.dart';
import '../ai_tool.dart';

class RecordGoalProgressTool extends AiTool {
  @override
  String get name => 'record_goal_progress';

  @override
  String get description => "Records progress for a task goal.";

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'properties': {
          'task_id': {
            'type': 'string',
            'description': 'ID of the task',
          },
          'numeric_amount': {
            'type': 'number',
            'description': 'Amount to add (for numeric goals)',
          },
          'habit_success': {
            'type': 'boolean',
            'description': 'Whether habit was successful (for habit goals)',
          },
          'note': {
            'type': 'string',
            'description': 'Optional note',
          },
        },
        'required': ['task_id'],
      };

  @override
  String describeAction(Map<String, dynamic> args) {
     return "Record progress for task ${args['task_id']}";
  }

  @override
  Future<Map<String, dynamic>> execute(Map<String, dynamic> args, DataService dataService) async {
    final taskId = args['task_id'] as String;
    
    final amountVal = args['numeric_amount'];
    double? numericAmount;
    if (amountVal != null) {
      numericAmount = (amountVal is num) 
          ? amountVal.toDouble() 
          : double.tryParse(amountVal.toString());
    }

    final habitSuccess = args['habit_success'] as bool?;
    final note = args['note'] as String?;

    dataService.recordGoalProgress(
      taskId,
      amount: numericAmount,
      isSuccess: habitSuccess,
      note: note,
    );
    
    return {'result': 'success', 'message': "Progress recorded for task $taskId"};
  }
}