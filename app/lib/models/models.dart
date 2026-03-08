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

extension AiStatusExtension on AiStatus {
  AiStatus get nextStatus {
    switch (this) {
      case AiStatus.notReady: return AiStatus.ready;
      case AiStatus.ready: return AiStatus.inProgress;
      case AiStatus.inProgress: return AiStatus.done;
      case AiStatus.done: return AiStatus.notReady;
    }
  }
}

extension TagExtractionExtension on String {
  List<String> extractTags() {
    final regex = RegExp(r'#[\w\u00C0-\u017F-]+');
    return regex.allMatches(this).map((m) => m.group(0)!).toList();
  }
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

class GoalMetadata {
  final double? progress;
  final String? label;
  final List<bool>? recentHabitHistory;

  GoalMetadata({this.progress, this.label, this.recentHabitHistory});
}

extension TaskGoalMetadataExtension on Task {
  GoalMetadata? get goalMetadata {
    if (goal != null) {
      return goal!.map(
        numeric: (n) {
          final pct = n.target == 0 ? 0.0 : (n.current / n.target).clamp(0.0, 1.0);
          return GoalMetadata(
            progress: pct,
            label: "${n.current}${n.unit ?? ''} / ${n.target}${n.unit ?? ''}",
          );
        },
        habit: (h) {
          final today = DateTime.now();
          final recent = <bool>[];
          for (int i = 4; i >= 0; i--) {
            final d = today.subtract(Duration(days: i));
            final entry = h.history
                .where((r) => r.date.year == d.year && r.date.month == d.month && r.date.day == d.day)
                .firstOrNull;
            recent.add(entry?.isSuccess ?? false);
          }
          final successCount = h.history.where((r) => r.isSuccess).length;
          final totalCount = h.history.length;
          final pct = totalCount > 0 ? (successCount / totalCount * 100).toInt() : 0;
          return GoalMetadata(
            recentHabitHistory: recent,
            label: "${(h.targetFrequency * 100).toInt()}% Target | $pct% Actual",
          );
        },
      );
    } else if (subtasks.isNotEmpty) {
      final total = subtasks.length;
      final completed = subtasks.where((s) => s.isCompleted).length;
      if (total > 0) {
        return GoalMetadata(
          progress: completed / total,
          label: "$completed/$total",
        );
      }
    }
    return null;
  }
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