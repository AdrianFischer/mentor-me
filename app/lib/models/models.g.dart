// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'models.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

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
