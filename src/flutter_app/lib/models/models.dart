import 'package:freezed_annotation/freezed_annotation.dart';

part 'models.freezed.dart';
part 'models.g.dart';

@freezed
class Subtask with _$Subtask {
  const factory Subtask({
    required String id,
    required String title,
    @Default(false) bool isCompleted,
  }) = _Subtask;

  factory Subtask.fromJson(Map<String, dynamic> json) => _$SubtaskFromJson(json);
}

@freezed
class Task with _$Task {
  const factory Task({
    required String id,
    required String title,
    @Default(false) bool isCompleted,
    String? projectId,
    @Default([]) List<Subtask> subtasks,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);
}

@freezed
class Project with _$Project {
  const factory Project({
    required String id,
    required String title,
    @Default([]) List<Task> tasks,
  }) = _Project;

  factory Project.fromJson(Map<String, dynamic> json) => _$ProjectFromJson(json);
}