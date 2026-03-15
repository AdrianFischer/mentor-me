// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'node.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$NodeImpl _$$NodeImplFromJson(Map<String, dynamic> json) => _$NodeImpl(
      id: json['id'] as String,
      title: json['title'] as String,
      isCompleted: json['isCompleted'] as bool? ?? false,
      order: (json['order'] as num?)?.toDouble() ?? 0.0,
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const [],
      notes: json['notes'] as String?,
      parentId: json['parentId'] as String?,
      aiStatus: $enumDecodeNullable(_$AiStatusEnumMap, json['aiStatus']) ??
          AiStatus.notReady,
      localImagePaths: (json['localImagePaths'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      children: (json['children'] as List<dynamic>?)
              ?.map((e) => Node.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      goal: json['goal'] == null
          ? null
          : TaskGoal.fromJson(json['goal'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$$NodeImplToJson(_$NodeImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'title': instance.title,
      'isCompleted': instance.isCompleted,
      'order': instance.order,
      'tags': instance.tags,
      'notes': instance.notes,
      'parentId': instance.parentId,
      'aiStatus': _$AiStatusEnumMap[instance.aiStatus]!,
      'localImagePaths': instance.localImagePaths,
      'children': instance.children,
      'goal': instance.goal,
    };

const _$AiStatusEnumMap = {
  AiStatus.notReady: 'notReady',
  AiStatus.ready: 'ready',
  AiStatus.inProgress: 'inProgress',
  AiStatus.done: 'done',
};
