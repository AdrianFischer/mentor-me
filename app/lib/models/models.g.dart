// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$SubtaskImpl _$$SubtaskImplFromJson(Map<String, dynamic> json) =>
    _$SubtaskImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      notes: json['notes'] as String?,
      aiStatus: $enumDecodeNullable(_$AiStatusEnumMap, json['aiStatus']) ??
          AiStatus.notReady,
      localImagePaths: (json['localImagePaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$SubtaskImplToJson(_$SubtaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'isCompleted': instance.isCompleted,
      'order': instance.order,
      'tags': instance.tags,
      'notes': instance.notes,
      'aiStatus': _$AiStatusEnumMap[instance.aiStatus]!,
      'localImagePaths': instance.localImagePaths,
    };

const _$AiStatusEnumMap = {
  AiStatus.notReady: 'notReady',
  AiStatus.ready: 'ready',
  AiStatus.inProgress: 'inProgress',
  AiStatus.done: 'done',
};

_$GoalTransactionImpl _$$GoalTransactionImplFromJson(
        Map<String, dynamic> json) =>
    _$GoalTransactionImpl(
      id: json['id'] as String,
      amount: (json['amount'] as num).toDouble(),
      date: DateTime.parse(json['date'] as String),
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$GoalTransactionImplToJson(
        _$GoalTransactionImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'amount': instance.amount,
      'date': instance.date.toIso8601String(),
      'note': instance.note,
    };

_$HabitRecordImpl _$$HabitRecordImplFromJson(Map<String, dynamic> json) =>
    _$HabitRecordImpl(
      date: DateTime.parse(json['date'] as String),
      isSuccess: json['isSuccess'] as bool,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$HabitRecordImplToJson(_$HabitRecordImpl instance) =>
    <String, dynamic>{
      'date': instance.date.toIso8601String(),
      'isSuccess': instance.isSuccess,
      'note': instance.note,
    };

_$NumericGoalImpl _$$NumericGoalImplFromJson(Map<String, dynamic> json) =>
    _$NumericGoalImpl(
      target: (json['target'] as num).toDouble(),
      current: (json['current'] as num?)?.toDouble() ?? 0.0,
      unit: json['unit'] as String?,
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => GoalTransaction.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$NumericGoalImplToJson(_$NumericGoalImpl instance) =>
    <String, dynamic>{
      'target': instance.target,
      'current': instance.current,
      'unit': instance.unit,
      'history': instance.history,
      'runtimeType': instance.$type,
    };

_$HabitGoalImpl _$$HabitGoalImplFromJson(Map<String, dynamic> json) =>
    _$HabitGoalImpl(
      targetFrequency: (json['targetFrequency'] as num).toDouble(),
      history: (json['history'] as List<dynamic>?)
              ?.map((e) => HabitRecord.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      $type: json['runtimeType'] as String?,
    );

Map<String, dynamic> _$$HabitGoalImplToJson(_$HabitGoalImpl instance) =>
    <String, dynamic>{
      'targetFrequency': instance.targetFrequency,
      'history': instance.history,
      'runtimeType': instance.$type,
    };

_$TaskImpl _$$TaskImplFromJson(Map<String, dynamic> json) => _$TaskImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      projectId: json['projectId'] as String?,
      subtasks: (json['subtasks'] as List<dynamic>?)
              ?.map((e) => Subtask.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      goal: json['goal'] == null
          ? null
          : TaskGoal.fromJson(json['goal'] as Map<String, dynamic>),
      notes: json['notes'] as String?,
      aiStatus: $enumDecodeNullable(_$AiStatusEnumMap, json['aiStatus']) ??
          AiStatus.notReady,
      localImagePaths: (json['localImagePaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$TaskImplToJson(_$TaskImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'isCompleted': instance.isCompleted,
      'projectId': instance.projectId,
      'subtasks': instance.subtasks,
      'order': instance.order,
      'tags': instance.tags,
      'goal': instance.goal,
      'notes': instance.notes,
      'aiStatus': _$AiStatusEnumMap[instance.aiStatus]!,
      'localImagePaths': instance.localImagePaths,
    };

_$ProjectImpl _$$ProjectImplFromJson(Map<String, dynamic> json) =>
    _$ProjectImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      tasks: (json['tasks'] as List<dynamic>?)
              ?.map((e) => Task.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      notes: json['notes'] as String?,
    );

Map<String, dynamic> _$$ProjectImplToJson(_$ProjectImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'tasks': instance.tasks,
      'order': instance.order,
      'tags': instance.tags,
      'notes': instance.notes,
    };
