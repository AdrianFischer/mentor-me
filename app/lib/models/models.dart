import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

enum AiStatus {
  @JsonValue('notReady')
  notReady,
  @JsonValue('ready')
  ready,
  @JsonValue('inProgress')
  inProgress,
  @JsonValue('done')
  done,
}

@freezed
class Subtask with _$Subtask {
  const factory Subtask({
    required String id,
    required String title,
    @Default(false) bool isCompleted,
    @Default(0.0) double order,
    @Default([]) List<String> tags,
    String? notes,
    @Default(AiStatus.notReady) AiStatus aiStatus,
    @Default([]) List<String> localImagePaths,
  }) = _Subtask;

  factory Subtask.fromJson(Map<String, dynamic> json) => _$SubtaskFromJson(json);
}

@freezed
class GoalTransaction with _$GoalTransaction {
  const factory GoalTransaction({
    required String id,
    required double amount,
    required DateTime date,
    String? note,
  }) = _GoalTransaction;

  factory GoalTransaction.fromJson(Map<String, dynamic> json) => _$GoalTransactionFromJson(json);
}

@freezed
class HabitRecord with _$HabitRecord {
  const factory HabitRecord({
    required DateTime date,
    required bool isSuccess,
    String? note,
  }) = _HabitRecord;

  factory HabitRecord.fromJson(Map<String, dynamic> json) => _$HabitRecordFromJson(json);
}

@freezed
sealed class TaskGoal with _$TaskGoal {
  const factory TaskGoal.numeric({
    required double target,
    @Default(0.0) double current,
    String? unit,
    @Default([]) List<GoalTransaction> history,
  }) = NumericGoal;

  const factory TaskGoal.habit({
    required double targetFrequency, // e.g. 0.9 for 90%
    @Default([]) List<HabitRecord> history, 
  }) = HabitGoal;

  factory TaskGoal.fromJson(Map<String, dynamic> json) => _$TaskGoalFromJson(json);
}

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    @Default(false) bool isCompleted,
    String? projectId,
    @Default([]) List<Subtask> subtasks,
    @Default(0.0) double order,
    @Default([]) List<String> tags,
    TaskGoal? goal,
    String? notes,
    @Default(AiStatus.notReady) AiStatus aiStatus,
    @Default([]) List<String> localImagePaths,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String title,
    @Default([]) List<Task> tasks,
    @Default(0.0) double order,
    @Default([]) List<String> tags,
    String? notes,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}