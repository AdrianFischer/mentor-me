// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'node.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Node _$NodeFromJson(Map<String, dynamic> json) {
  return _Node.fromJson(json);
}

/// @nodoc
mixin _$Node {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  double get order => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  String? get parentId => throw _privateConstructorUsedError;
  AiStatus get aiStatus => throw _privateConstructorUsedError;
  List<String> get localImagePaths => throw _privateConstructorUsedError;
  List<Node> get children => throw _privateConstructorUsedError;
  TaskGoal? get goal => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $NodeCopyWith<Node> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NodeCopyWith<$Res> {
  factory $NodeCopyWith(Node value, $Res Function(Node) then) =
      _$NodeCopyWithImpl<$Res, Node>;
  @useResult
  $Res call(
      {String id,
      String title,
      bool isCompleted,
      double order,
      List<String> tags,
      String? notes,
      String? parentId,
      AiStatus aiStatus,
      List<String> localImagePaths,
      List<Node> children,
      TaskGoal? goal});

  $TaskGoalCopyWith<$Res>? get goal;
}

/// @nodoc
class _$NodeCopyWithImpl<$Res, $Val extends Node>
    implements $NodeCopyWith<$Res> {
  _$NodeCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? isCompleted = null,
    Object? order = null,
    Object? tags = null,
    Object? notes = freezed,
    Object? parentId = freezed,
    Object? aiStatus = null,
    Object? localImagePaths = null,
    Object? children = null,
    Object? goal = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as double,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      aiStatus: null == aiStatus
          ? _value.aiStatus
          : aiStatus // ignore: cast_nullable_to_non_nullable
              as AiStatus,
      localImagePaths: null == localImagePaths
          ? _value.localImagePaths
          : localImagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      children: null == children
          ? _value.children
          : children // ignore: cast_nullable_to_non_nullable
              as List<Node>,
      goal: freezed == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as TaskGoal?,
    ) as $Val);
  }

  @override
  @pragma('vm:prefer-inline')
  $TaskGoalCopyWith<$Res>? get goal {
    if (_value.goal == null) {
      return null;
    }

    return $TaskGoalCopyWith<$Res>(_value.goal!, (value) {
      return _then(_value.copyWith(goal: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$NodeImplCopyWith<$Res> implements $NodeCopyWith<$Res> {
  factory _$$NodeImplCopyWith(
          _$NodeImpl value, $Res Function(_$NodeImpl) then) =
      __$$NodeImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      bool isCompleted,
      double order,
      List<String> tags,
      String? notes,
      String? parentId,
      AiStatus aiStatus,
      List<String> localImagePaths,
      List<Node> children,
      TaskGoal? goal});

  @override
  $TaskGoalCopyWith<$Res>? get goal;
}

/// @nodoc
class __$$NodeImplCopyWithImpl<$Res>
    extends _$NodeCopyWithImpl<$Res, _$NodeImpl>
    implements _$$NodeImplCopyWith<$Res> {
  __$$NodeImplCopyWithImpl(_$NodeImpl _value, $Res Function(_$NodeImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? isCompleted = null,
    Object? order = null,
    Object? tags = null,
    Object? notes = freezed,
    Object? parentId = freezed,
    Object? aiStatus = null,
    Object? localImagePaths = null,
    Object? children = null,
    Object? goal = freezed,
  }) {
    return _then(_$NodeImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      isCompleted: null == isCompleted
          ? _value.isCompleted
          : isCompleted // ignore: cast_nullable_to_non_nullable
              as bool,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as double,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      parentId: freezed == parentId
          ? _value.parentId
          : parentId // ignore: cast_nullable_to_non_nullable
              as String?,
      aiStatus: null == aiStatus
          ? _value.aiStatus
          : aiStatus // ignore: cast_nullable_to_non_nullable
              as AiStatus,
      localImagePaths: null == localImagePaths
          ? _value._localImagePaths
          : localImagePaths // ignore: cast_nullable_to_non_nullable
              as List<String>,
      children: null == children
          ? _value._children
          : children // ignore: cast_nullable_to_non_nullable
              as List<Node>,
      goal: freezed == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as TaskGoal?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NodeImpl extends _Node {
  const _$NodeImpl(
      {required this.id,
      required this.title,
      this.isCompleted = false,
      this.order = 0.0,
      final List<String> tags = const [],
      this.notes,
      this.parentId,
      this.aiStatus = AiStatus.notReady,
      final List<String> localImagePaths = const [],
      final List<Node> children = const [],
      this.goal})
      : _tags = tags,
        _localImagePaths = localImagePaths,
        _children = children,
        super._();

  factory _$NodeImpl.fromJson(Map<String, dynamic> json) =>
      _$$NodeImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  @JsonKey()
  final double order;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  @override
  final String? notes;
  @override
  final String? parentId;
  @override
  @JsonKey()
  final AiStatus aiStatus;
  final List<String> _localImagePaths;
  @override
  @JsonKey()
  List<String> get localImagePaths {
    if (_localImagePaths is EqualUnmodifiableListView) return _localImagePaths;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_localImagePaths);
  }

  final List<Node> _children;
  @override
  @JsonKey()
  List<Node> get children {
    if (_children is EqualUnmodifiableListView) return _children;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_children);
  }

  @override
  final TaskGoal? goal;

  @override
  String toString() {
    return 'Node(id: $id, title: $title, isCompleted: $isCompleted, order: $order, tags: $tags, notes: $notes, parentId: $parentId, aiStatus: $aiStatus, localImagePaths: $localImagePaths, children: $children, goal: $goal)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NodeImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.parentId, parentId) ||
                other.parentId == parentId) &&
            (identical(other.aiStatus, aiStatus) ||
                other.aiStatus == aiStatus) &&
            const DeepCollectionEquality()
                .equals(other._localImagePaths, _localImagePaths) &&
            const DeepCollectionEquality().equals(other._children, _children) &&
            (identical(other.goal, goal) || other.goal == goal));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      isCompleted,
      order,
      const DeepCollectionEquality().hash(_tags),
      notes,
      parentId,
      aiStatus,
      const DeepCollectionEquality().hash(_localImagePaths),
      const DeepCollectionEquality().hash(_children),
      goal);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NodeImplCopyWith<_$NodeImpl> get copyWith =>
      __$$NodeImplCopyWithImpl<_$NodeImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NodeImplToJson(
      this,
    );
  }
}

abstract class _Node extends Node {
  const factory _Node(
      {required final String id,
      required final String title,
      final bool isCompleted,
      final double order,
      final List<String> tags,
      final String? notes,
      final String? parentId,
      final AiStatus aiStatus,
      final List<String> localImagePaths,
      final List<Node> children,
      final TaskGoal? goal}) = _$NodeImpl;
  const _Node._() : super._();

  factory _Node.fromJson(Map<String, dynamic> json) = _$NodeImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  bool get isCompleted;
  @override
  double get order;
  @override
  List<String> get tags;
  @override
  String? get notes;
  @override
  String? get parentId;
  @override
  AiStatus get aiStatus;
  @override
  List<String> get localImagePaths;
  @override
  List<Node> get children;
  @override
  TaskGoal? get goal;
  @override
  @JsonKey(ignore: true)
  _$$NodeImplCopyWith<_$NodeImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
