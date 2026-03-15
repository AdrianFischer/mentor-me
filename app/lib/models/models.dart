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
    required double targetFrequency,
    @Default([]) List<HabitRecord> history,
  }) = HabitGoal;

  factory TaskGoal.fromJson(Map<String, dynamic> json) => _$TaskGoalFromJson(json);
}

class GoalMetadata {
  final double? progress;
  final String? label;
  final List<bool>? recentHabitHistory;

  GoalMetadata({this.progress, this.label, this.recentHabitHistory});
}
