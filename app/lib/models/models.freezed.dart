// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'models.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

Subtask _$SubtaskFromJson(Map<String, dynamic> json) {
  return _Subtask.fromJson(json);
}

/// @nodoc
mixin _$Subtask {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  double get order => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  AiStatus get aiStatus => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $SubtaskCopyWith<Subtask> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $SubtaskCopyWith<$Res> {
  factory $SubtaskCopyWith(Subtask value, $Res Function(Subtask) then) =
      _$SubtaskCopyWithImpl<$Res, Subtask>;
  @useResult
  $Res call(
      {String id,
      String title,
      bool isCompleted,
      double order,
      List<String> tags,
      String? notes,
      AiStatus aiStatus});
}

/// @nodoc
class _$SubtaskCopyWithImpl<$Res, $Val extends Subtask>
    implements $SubtaskCopyWith<$Res> {
  _$SubtaskCopyWithImpl(this._value, this._then);

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
    Object? aiStatus = null,
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
      aiStatus: null == aiStatus
          ? _value.aiStatus
          : aiStatus // ignore: cast_nullable_to_non_nullable
              as AiStatus,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$SubtaskImplCopyWith<$Res> implements $SubtaskCopyWith<$Res> {
  factory _$$SubtaskImplCopyWith(
          _$SubtaskImpl value, $Res Function(_$SubtaskImpl) then) =
      __$$SubtaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      bool isCompleted,
      double order,
      List<String> tags,
      String? notes,
      AiStatus aiStatus});
}

/// @nodoc
class __$$SubtaskImplCopyWithImpl<$Res>
    extends _$SubtaskCopyWithImpl<$Res, _$SubtaskImpl>
    implements _$$SubtaskImplCopyWith<$Res> {
  __$$SubtaskImplCopyWithImpl(
      _$SubtaskImpl _value, $Res Function(_$SubtaskImpl) _then)
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
    Object? aiStatus = null,
  }) {
    return _then(_$SubtaskImpl(
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
      aiStatus: null == aiStatus
          ? _value.aiStatus
          : aiStatus // ignore: cast_nullable_to_non_nullable
              as AiStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$SubtaskImpl implements _Subtask {
  const _$SubtaskImpl(
      {required this.id,
      required this.title,
      this.isCompleted = false,
      this.order = 0.0,
      final List<String> tags = const [],
      this.notes,
      this.aiStatus = AiStatus.notReady})
      : _tags = tags;

  factory _$SubtaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$SubtaskImplFromJson(json);

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
  @JsonKey()
  final AiStatus aiStatus;

  @override
  String toString() {
    return 'Subtask(id: $id, title: $title, isCompleted: $isCompleted, order: $order, tags: $tags, notes: $notes, aiStatus: $aiStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$SubtaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.aiStatus, aiStatus) ||
                other.aiStatus == aiStatus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, title, isCompleted, order,
      const DeepCollectionEquality().hash(_tags), notes, aiStatus);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$SubtaskImplCopyWith<_$SubtaskImpl> get copyWith =>
      __$$SubtaskImplCopyWithImpl<_$SubtaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$SubtaskImplToJson(
      this,
    );
  }
}

abstract class _Subtask implements Subtask {
  const factory _Subtask(
      {required final String id,
      required final String title,
      final bool isCompleted,
      final double order,
      final List<String> tags,
      final String? notes,
      final AiStatus aiStatus}) = _$SubtaskImpl;

  factory _Subtask.fromJson(Map<String, dynamic> json) = _$SubtaskImpl.fromJson;

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
  AiStatus get aiStatus;
  @override
  @JsonKey(ignore: true)
  _$$SubtaskImplCopyWith<_$SubtaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

GoalTransaction _$GoalTransactionFromJson(Map<String, dynamic> json) {
  return _GoalTransaction.fromJson(json);
}

/// @nodoc
mixin _$GoalTransaction {
  String get id => throw _privateConstructorUsedError;
  double get amount => throw _privateConstructorUsedError;
  DateTime get date => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $GoalTransactionCopyWith<GoalTransaction> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $GoalTransactionCopyWith<$Res> {
  factory $GoalTransactionCopyWith(
          GoalTransaction value, $Res Function(GoalTransaction) then) =
      _$GoalTransactionCopyWithImpl<$Res, GoalTransaction>;
  @useResult
  $Res call({String id, double amount, DateTime date, String? note});
}

/// @nodoc
class _$GoalTransactionCopyWithImpl<$Res, $Val extends GoalTransaction>
    implements $GoalTransactionCopyWith<$Res> {
  _$GoalTransactionCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amount = null,
    Object? date = null,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$GoalTransactionImplCopyWith<$Res>
    implements $GoalTransactionCopyWith<$Res> {
  factory _$$GoalTransactionImplCopyWith(_$GoalTransactionImpl value,
          $Res Function(_$GoalTransactionImpl) then) =
      __$$GoalTransactionImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String id, double amount, DateTime date, String? note});
}

/// @nodoc
class __$$GoalTransactionImplCopyWithImpl<$Res>
    extends _$GoalTransactionCopyWithImpl<$Res, _$GoalTransactionImpl>
    implements _$$GoalTransactionImplCopyWith<$Res> {
  __$$GoalTransactionImplCopyWithImpl(
      _$GoalTransactionImpl _value, $Res Function(_$GoalTransactionImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? amount = null,
    Object? date = null,
    Object? note = freezed,
  }) {
    return _then(_$GoalTransactionImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as double,
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$GoalTransactionImpl implements _GoalTransaction {
  const _$GoalTransactionImpl(
      {required this.id, required this.amount, required this.date, this.note});

  factory _$GoalTransactionImpl.fromJson(Map<String, dynamic> json) =>
      _$$GoalTransactionImplFromJson(json);

  @override
  final String id;
  @override
  final double amount;
  @override
  final DateTime date;
  @override
  final String? note;

  @override
  String toString() {
    return 'GoalTransaction(id: $id, amount: $amount, date: $date, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$GoalTransactionImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, id, amount, date, note);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$GoalTransactionImplCopyWith<_$GoalTransactionImpl> get copyWith =>
      __$$GoalTransactionImplCopyWithImpl<_$GoalTransactionImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$GoalTransactionImplToJson(
      this,
    );
  }
}

abstract class _GoalTransaction implements GoalTransaction {
  const factory _GoalTransaction(
      {required final String id,
      required final double amount,
      required final DateTime date,
      final String? note}) = _$GoalTransactionImpl;

  factory _GoalTransaction.fromJson(Map<String, dynamic> json) =
      _$GoalTransactionImpl.fromJson;

  @override
  String get id;
  @override
  double get amount;
  @override
  DateTime get date;
  @override
  String? get note;
  @override
  @JsonKey(ignore: true)
  _$$GoalTransactionImplCopyWith<_$GoalTransactionImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

HabitRecord _$HabitRecordFromJson(Map<String, dynamic> json) {
  return _HabitRecord.fromJson(json);
}

/// @nodoc
mixin _$HabitRecord {
  DateTime get date => throw _privateConstructorUsedError;
  bool get isSuccess => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $HabitRecordCopyWith<HabitRecord> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $HabitRecordCopyWith<$Res> {
  factory $HabitRecordCopyWith(
          HabitRecord value, $Res Function(HabitRecord) then) =
      _$HabitRecordCopyWithImpl<$Res, HabitRecord>;
  @useResult
  $Res call({DateTime date, bool isSuccess, String? note});
}

/// @nodoc
class _$HabitRecordCopyWithImpl<$Res, $Val extends HabitRecord>
    implements $HabitRecordCopyWith<$Res> {
  _$HabitRecordCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? isSuccess = null,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$HabitRecordImplCopyWith<$Res>
    implements $HabitRecordCopyWith<$Res> {
  factory _$$HabitRecordImplCopyWith(
          _$HabitRecordImpl value, $Res Function(_$HabitRecordImpl) then) =
      __$$HabitRecordImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({DateTime date, bool isSuccess, String? note});
}

/// @nodoc
class __$$HabitRecordImplCopyWithImpl<$Res>
    extends _$HabitRecordCopyWithImpl<$Res, _$HabitRecordImpl>
    implements _$$HabitRecordImplCopyWith<$Res> {
  __$$HabitRecordImplCopyWithImpl(
      _$HabitRecordImpl _value, $Res Function(_$HabitRecordImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? date = null,
    Object? isSuccess = null,
    Object? note = freezed,
  }) {
    return _then(_$HabitRecordImpl(
      date: null == date
          ? _value.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      isSuccess: null == isSuccess
          ? _value.isSuccess
          : isSuccess // ignore: cast_nullable_to_non_nullable
              as bool,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HabitRecordImpl implements _HabitRecord {
  const _$HabitRecordImpl(
      {required this.date, required this.isSuccess, this.note});

  factory _$HabitRecordImpl.fromJson(Map<String, dynamic> json) =>
      _$$HabitRecordImplFromJson(json);

  @override
  final DateTime date;
  @override
  final bool isSuccess;
  @override
  final String? note;

  @override
  String toString() {
    return 'HabitRecord(date: $date, isSuccess: $isSuccess, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HabitRecordImpl &&
            (identical(other.date, date) || other.date == date) &&
            (identical(other.isSuccess, isSuccess) ||
                other.isSuccess == isSuccess) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, date, isSuccess, note);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HabitRecordImplCopyWith<_$HabitRecordImpl> get copyWith =>
      __$$HabitRecordImplCopyWithImpl<_$HabitRecordImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$HabitRecordImplToJson(
      this,
    );
  }
}

abstract class _HabitRecord implements HabitRecord {
  const factory _HabitRecord(
      {required final DateTime date,
      required final bool isSuccess,
      final String? note}) = _$HabitRecordImpl;

  factory _HabitRecord.fromJson(Map<String, dynamic> json) =
      _$HabitRecordImpl.fromJson;

  @override
  DateTime get date;
  @override
  bool get isSuccess;
  @override
  String? get note;
  @override
  @JsonKey(ignore: true)
  _$$HabitRecordImplCopyWith<_$HabitRecordImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

TaskGoal _$TaskGoalFromJson(Map<String, dynamic> json) {
  switch (json['runtimeType']) {
    case 'numeric':
      return NumericGoal.fromJson(json);
    case 'habit':
      return HabitGoal.fromJson(json);

    default:
      throw CheckedFromJsonException(json, 'runtimeType', 'TaskGoal',
          'Invalid union type "${json['runtimeType']}"!');
  }
}

/// @nodoc
mixin _$TaskGoal {
  List<Object> get history => throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(double target, double current, String? unit,
            List<GoalTransaction> history)
        numeric,
    required TResult Function(double targetFrequency, List<HabitRecord> history)
        habit,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(double target, double current, String? unit,
            List<GoalTransaction> history)?
        numeric,
    TResult? Function(double targetFrequency, List<HabitRecord> history)? habit,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(double target, double current, String? unit,
            List<GoalTransaction> history)?
        numeric,
    TResult Function(double targetFrequency, List<HabitRecord> history)? habit,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NumericGoal value) numeric,
    required TResult Function(HabitGoal value) habit,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NumericGoal value)? numeric,
    TResult? Function(HabitGoal value)? habit,
  }) =>
      throw _privateConstructorUsedError;
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NumericGoal value)? numeric,
    TResult Function(HabitGoal value)? habit,
    required TResult orElse(),
  }) =>
      throw _privateConstructorUsedError;
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskGoalCopyWith<$Res> {
  factory $TaskGoalCopyWith(TaskGoal value, $Res Function(TaskGoal) then) =
      _$TaskGoalCopyWithImpl<$Res, TaskGoal>;
}

/// @nodoc
class _$TaskGoalCopyWithImpl<$Res, $Val extends TaskGoal>
    implements $TaskGoalCopyWith<$Res> {
  _$TaskGoalCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;
}

/// @nodoc
abstract class _$$NumericGoalImplCopyWith<$Res> {
  factory _$$NumericGoalImplCopyWith(
          _$NumericGoalImpl value, $Res Function(_$NumericGoalImpl) then) =
      __$$NumericGoalImplCopyWithImpl<$Res>;
  @useResult
  $Res call(
      {double target,
      double current,
      String? unit,
      List<GoalTransaction> history});
}

/// @nodoc
class __$$NumericGoalImplCopyWithImpl<$Res>
    extends _$TaskGoalCopyWithImpl<$Res, _$NumericGoalImpl>
    implements _$$NumericGoalImplCopyWith<$Res> {
  __$$NumericGoalImplCopyWithImpl(
      _$NumericGoalImpl _value, $Res Function(_$NumericGoalImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? target = null,
    Object? current = null,
    Object? unit = freezed,
    Object? history = null,
  }) {
    return _then(_$NumericGoalImpl(
      target: null == target
          ? _value.target
          : target // ignore: cast_nullable_to_non_nullable
              as double,
      current: null == current
          ? _value.current
          : current // ignore: cast_nullable_to_non_nullable
              as double,
      unit: freezed == unit
          ? _value.unit
          : unit // ignore: cast_nullable_to_non_nullable
              as String?,
      history: null == history
          ? _value._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<GoalTransaction>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NumericGoalImpl implements NumericGoal {
  const _$NumericGoalImpl(
      {required this.target,
      this.current = 0.0,
      this.unit,
      final List<GoalTransaction> history = const [],
      final String? $type})
      : _history = history,
        $type = $type ?? 'numeric';

  factory _$NumericGoalImpl.fromJson(Map<String, dynamic> json) =>
      _$$NumericGoalImplFromJson(json);

  @override
  final double target;
  @override
  @JsonKey()
  final double current;
  @override
  final String? unit;
  final List<GoalTransaction> _history;
  @override
  @JsonKey()
  List<GoalTransaction> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'TaskGoal.numeric(target: $target, current: $current, unit: $unit, history: $history)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NumericGoalImpl &&
            (identical(other.target, target) || other.target == target) &&
            (identical(other.current, current) || other.current == current) &&
            (identical(other.unit, unit) || other.unit == unit) &&
            const DeepCollectionEquality().equals(other._history, _history));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, target, current, unit,
      const DeepCollectionEquality().hash(_history));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$NumericGoalImplCopyWith<_$NumericGoalImpl> get copyWith =>
      __$$NumericGoalImplCopyWithImpl<_$NumericGoalImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(double target, double current, String? unit,
            List<GoalTransaction> history)
        numeric,
    required TResult Function(double targetFrequency, List<HabitRecord> history)
        habit,
  }) {
    return numeric(target, current, unit, history);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(double target, double current, String? unit,
            List<GoalTransaction> history)?
        numeric,
    TResult? Function(double targetFrequency, List<HabitRecord> history)? habit,
  }) {
    return numeric?.call(target, current, unit, history);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(double target, double current, String? unit,
            List<GoalTransaction> history)?
        numeric,
    TResult Function(double targetFrequency, List<HabitRecord> history)? habit,
    required TResult orElse(),
  }) {
    if (numeric != null) {
      return numeric(target, current, unit, history);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NumericGoal value) numeric,
    required TResult Function(HabitGoal value) habit,
  }) {
    return numeric(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NumericGoal value)? numeric,
    TResult? Function(HabitGoal value)? habit,
  }) {
    return numeric?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NumericGoal value)? numeric,
    TResult Function(HabitGoal value)? habit,
    required TResult orElse(),
  }) {
    if (numeric != null) {
      return numeric(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$NumericGoalImplToJson(
      this,
    );
  }
}

abstract class NumericGoal implements TaskGoal {
  const factory NumericGoal(
      {required final double target,
      final double current,
      final String? unit,
      final List<GoalTransaction> history}) = _$NumericGoalImpl;

  factory NumericGoal.fromJson(Map<String, dynamic> json) =
      _$NumericGoalImpl.fromJson;

  double get target;
  double get current;
  String? get unit;
  @override
  List<GoalTransaction> get history;
  @JsonKey(ignore: true)
  _$$NumericGoalImplCopyWith<_$NumericGoalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class _$$HabitGoalImplCopyWith<$Res> {
  factory _$$HabitGoalImplCopyWith(
          _$HabitGoalImpl value, $Res Function(_$HabitGoalImpl) then) =
      __$$HabitGoalImplCopyWithImpl<$Res>;
  @useResult
  $Res call({double targetFrequency, List<HabitRecord> history});
}

/// @nodoc
class __$$HabitGoalImplCopyWithImpl<$Res>
    extends _$TaskGoalCopyWithImpl<$Res, _$HabitGoalImpl>
    implements _$$HabitGoalImplCopyWith<$Res> {
  __$$HabitGoalImplCopyWithImpl(
      _$HabitGoalImpl _value, $Res Function(_$HabitGoalImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? targetFrequency = null,
    Object? history = null,
  }) {
    return _then(_$HabitGoalImpl(
      targetFrequency: null == targetFrequency
          ? _value.targetFrequency
          : targetFrequency // ignore: cast_nullable_to_non_nullable
              as double,
      history: null == history
          ? _value._history
          : history // ignore: cast_nullable_to_non_nullable
              as List<HabitRecord>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$HabitGoalImpl implements HabitGoal {
  const _$HabitGoalImpl(
      {required this.targetFrequency,
      final List<HabitRecord> history = const [],
      final String? $type})
      : _history = history,
        $type = $type ?? 'habit';

  factory _$HabitGoalImpl.fromJson(Map<String, dynamic> json) =>
      _$$HabitGoalImplFromJson(json);

  @override
  final double targetFrequency;
// e.g. 0.9 for 90%
  final List<HabitRecord> _history;
// e.g. 0.9 for 90%
  @override
  @JsonKey()
  List<HabitRecord> get history {
    if (_history is EqualUnmodifiableListView) return _history;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_history);
  }

  @JsonKey(name: 'runtimeType')
  final String $type;

  @override
  String toString() {
    return 'TaskGoal.habit(targetFrequency: $targetFrequency, history: $history)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$HabitGoalImpl &&
            (identical(other.targetFrequency, targetFrequency) ||
                other.targetFrequency == targetFrequency) &&
            const DeepCollectionEquality().equals(other._history, _history));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(runtimeType, targetFrequency,
      const DeepCollectionEquality().hash(_history));

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$HabitGoalImplCopyWith<_$HabitGoalImpl> get copyWith =>
      __$$HabitGoalImplCopyWithImpl<_$HabitGoalImpl>(this, _$identity);

  @override
  @optionalTypeArgs
  TResult when<TResult extends Object?>({
    required TResult Function(double target, double current, String? unit,
            List<GoalTransaction> history)
        numeric,
    required TResult Function(double targetFrequency, List<HabitRecord> history)
        habit,
  }) {
    return habit(targetFrequency, history);
  }

  @override
  @optionalTypeArgs
  TResult? whenOrNull<TResult extends Object?>({
    TResult? Function(double target, double current, String? unit,
            List<GoalTransaction> history)?
        numeric,
    TResult? Function(double targetFrequency, List<HabitRecord> history)? habit,
  }) {
    return habit?.call(targetFrequency, history);
  }

  @override
  @optionalTypeArgs
  TResult maybeWhen<TResult extends Object?>({
    TResult Function(double target, double current, String? unit,
            List<GoalTransaction> history)?
        numeric,
    TResult Function(double targetFrequency, List<HabitRecord> history)? habit,
    required TResult orElse(),
  }) {
    if (habit != null) {
      return habit(targetFrequency, history);
    }
    return orElse();
  }

  @override
  @optionalTypeArgs
  TResult map<TResult extends Object?>({
    required TResult Function(NumericGoal value) numeric,
    required TResult Function(HabitGoal value) habit,
  }) {
    return habit(this);
  }

  @override
  @optionalTypeArgs
  TResult? mapOrNull<TResult extends Object?>({
    TResult? Function(NumericGoal value)? numeric,
    TResult? Function(HabitGoal value)? habit,
  }) {
    return habit?.call(this);
  }

  @override
  @optionalTypeArgs
  TResult maybeMap<TResult extends Object?>({
    TResult Function(NumericGoal value)? numeric,
    TResult Function(HabitGoal value)? habit,
    required TResult orElse(),
  }) {
    if (habit != null) {
      return habit(this);
    }
    return orElse();
  }

  @override
  Map<String, dynamic> toJson() {
    return _$$HabitGoalImplToJson(
      this,
    );
  }
}

abstract class HabitGoal implements TaskGoal {
  const factory HabitGoal(
      {required final double targetFrequency,
      final List<HabitRecord> history}) = _$HabitGoalImpl;

  factory HabitGoal.fromJson(Map<String, dynamic> json) =
      _$HabitGoalImpl.fromJson;

  double get targetFrequency;
  @override // e.g. 0.9 for 90%
  List<HabitRecord> get history;
  @JsonKey(ignore: true)
  _$$HabitGoalImplCopyWith<_$HabitGoalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Task _$TaskFromJson(Map<String, dynamic> json) {
  return _Task.fromJson(json);
}

/// @nodoc
mixin _$Task {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  bool get isCompleted => throw _privateConstructorUsedError;
  String? get projectId => throw _privateConstructorUsedError;
  List<Subtask> get subtasks => throw _privateConstructorUsedError;
  double get order => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  TaskGoal? get goal => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;
  AiStatus get aiStatus => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $TaskCopyWith<Task> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $TaskCopyWith<$Res> {
  factory $TaskCopyWith(Task value, $Res Function(Task) then) =
      _$TaskCopyWithImpl<$Res, Task>;
  @useResult
  $Res call(
      {String id,
      String title,
      bool isCompleted,
      String? projectId,
      List<Subtask> subtasks,
      double order,
      List<String> tags,
      TaskGoal? goal,
      String? notes,
      AiStatus aiStatus});

  $TaskGoalCopyWith<$Res>? get goal;
}

/// @nodoc
class _$TaskCopyWithImpl<$Res, $Val extends Task>
    implements $TaskCopyWith<$Res> {
  _$TaskCopyWithImpl(this._value, this._then);

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
    Object? projectId = freezed,
    Object? subtasks = null,
    Object? order = null,
    Object? tags = null,
    Object? goal = freezed,
    Object? notes = freezed,
    Object? aiStatus = null,
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
      projectId: freezed == projectId
          ? _value.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      subtasks: null == subtasks
          ? _value.subtasks
          : subtasks // ignore: cast_nullable_to_non_nullable
              as List<Subtask>,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as double,
      tags: null == tags
          ? _value.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goal: freezed == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as TaskGoal?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      aiStatus: null == aiStatus
          ? _value.aiStatus
          : aiStatus // ignore: cast_nullable_to_non_nullable
              as AiStatus,
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
abstract class _$$TaskImplCopyWith<$Res> implements $TaskCopyWith<$Res> {
  factory _$$TaskImplCopyWith(
          _$TaskImpl value, $Res Function(_$TaskImpl) then) =
      __$$TaskImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      bool isCompleted,
      String? projectId,
      List<Subtask> subtasks,
      double order,
      List<String> tags,
      TaskGoal? goal,
      String? notes,
      AiStatus aiStatus});

  @override
  $TaskGoalCopyWith<$Res>? get goal;
}

/// @nodoc
class __$$TaskImplCopyWithImpl<$Res>
    extends _$TaskCopyWithImpl<$Res, _$TaskImpl>
    implements _$$TaskImplCopyWith<$Res> {
  __$$TaskImplCopyWithImpl(_$TaskImpl _value, $Res Function(_$TaskImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? isCompleted = null,
    Object? projectId = freezed,
    Object? subtasks = null,
    Object? order = null,
    Object? tags = null,
    Object? goal = freezed,
    Object? notes = freezed,
    Object? aiStatus = null,
  }) {
    return _then(_$TaskImpl(
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
      projectId: freezed == projectId
          ? _value.projectId
          : projectId // ignore: cast_nullable_to_non_nullable
              as String?,
      subtasks: null == subtasks
          ? _value._subtasks
          : subtasks // ignore: cast_nullable_to_non_nullable
              as List<Subtask>,
      order: null == order
          ? _value.order
          : order // ignore: cast_nullable_to_non_nullable
              as double,
      tags: null == tags
          ? _value._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
      goal: freezed == goal
          ? _value.goal
          : goal // ignore: cast_nullable_to_non_nullable
              as TaskGoal?,
      notes: freezed == notes
          ? _value.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as String?,
      aiStatus: null == aiStatus
          ? _value.aiStatus
          : aiStatus // ignore: cast_nullable_to_non_nullable
              as AiStatus,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$TaskImpl implements _Task {
  const _$TaskImpl(
      {required this.id,
      required this.title,
      this.isCompleted = false,
      this.projectId,
      final List<Subtask> subtasks = const [],
      this.order = 0.0,
      final List<String> tags = const [],
      this.goal,
      this.notes,
      this.aiStatus = AiStatus.notReady})
      : _subtasks = subtasks,
        _tags = tags;

  factory _$TaskImpl.fromJson(Map<String, dynamic> json) =>
      _$$TaskImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  @override
  @JsonKey()
  final bool isCompleted;
  @override
  final String? projectId;
  final List<Subtask> _subtasks;
  @override
  @JsonKey()
  List<Subtask> get subtasks {
    if (_subtasks is EqualUnmodifiableListView) return _subtasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_subtasks);
  }

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
  final TaskGoal? goal;
  @override
  final String? notes;
  @override
  @JsonKey()
  final AiStatus aiStatus;

  @override
  String toString() {
    return 'Task(id: $id, title: $title, isCompleted: $isCompleted, projectId: $projectId, subtasks: $subtasks, order: $order, tags: $tags, goal: $goal, notes: $notes, aiStatus: $aiStatus)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$TaskImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.isCompleted, isCompleted) ||
                other.isCompleted == isCompleted) &&
            (identical(other.projectId, projectId) ||
                other.projectId == projectId) &&
            const DeepCollectionEquality().equals(other._subtasks, _subtasks) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.goal, goal) || other.goal == goal) &&
            (identical(other.notes, notes) || other.notes == notes) &&
            (identical(other.aiStatus, aiStatus) ||
                other.aiStatus == aiStatus));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      isCompleted,
      projectId,
      const DeepCollectionEquality().hash(_subtasks),
      order,
      const DeepCollectionEquality().hash(_tags),
      goal,
      notes,
      aiStatus);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      __$$TaskImplCopyWithImpl<_$TaskImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$TaskImplToJson(
      this,
    );
  }
}

abstract class _Task implements Task {
  const factory _Task(
      {required final String id,
      required final String title,
      final bool isCompleted,
      final String? projectId,
      final List<Subtask> subtasks,
      final double order,
      final List<String> tags,
      final TaskGoal? goal,
      final String? notes,
      final AiStatus aiStatus}) = _$TaskImpl;

  factory _Task.fromJson(Map<String, dynamic> json) = _$TaskImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  bool get isCompleted;
  @override
  String? get projectId;
  @override
  List<Subtask> get subtasks;
  @override
  double get order;
  @override
  List<String> get tags;
  @override
  TaskGoal? get goal;
  @override
  String? get notes;
  @override
  AiStatus get aiStatus;
  @override
  @JsonKey(ignore: true)
  _$$TaskImplCopyWith<_$TaskImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

Project _$ProjectFromJson(Map<String, dynamic> json) {
  return _Project.fromJson(json);
}

/// @nodoc
mixin _$Project {
  String get id => throw _privateConstructorUsedError;
  String get title => throw _privateConstructorUsedError;
  List<Task> get tasks => throw _privateConstructorUsedError;
  double get order => throw _privateConstructorUsedError;
  List<String> get tags => throw _privateConstructorUsedError;
  String? get notes => throw _privateConstructorUsedError;

  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;
  @JsonKey(ignore: true)
  $ProjectCopyWith<Project> get copyWith => throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $ProjectCopyWith<$Res> {
  factory $ProjectCopyWith(Project value, $Res Function(Project) then) =
      _$ProjectCopyWithImpl<$Res, Project>;
  @useResult
  $Res call(
      {String id,
      String title,
      List<Task> tasks,
      double order,
      List<String> tags,
      String? notes});
}

/// @nodoc
class _$ProjectCopyWithImpl<$Res, $Val extends Project>
    implements $ProjectCopyWith<$Res> {
  _$ProjectCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? tasks = null,
    Object? order = null,
    Object? tags = null,
    Object? notes = freezed,
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
      tasks: null == tasks
          ? _value.tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<Task>,
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
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$ProjectImplCopyWith<$Res> implements $ProjectCopyWith<$Res> {
  factory _$$ProjectImplCopyWith(
          _$ProjectImpl value, $Res Function(_$ProjectImpl) then) =
      __$$ProjectImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String title,
      List<Task> tasks,
      double order,
      List<String> tags,
      String? notes});
}

/// @nodoc
class __$$ProjectImplCopyWithImpl<$Res>
    extends _$ProjectCopyWithImpl<$Res, _$ProjectImpl>
    implements _$$ProjectImplCopyWith<$Res> {
  __$$ProjectImplCopyWithImpl(
      _$ProjectImpl _value, $Res Function(_$ProjectImpl) _then)
      : super(_value, _then);

  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? title = null,
    Object? tasks = null,
    Object? order = null,
    Object? tags = null,
    Object? notes = freezed,
  }) {
    return _then(_$ProjectImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      title: null == title
          ? _value.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      tasks: null == tasks
          ? _value._tasks
          : tasks // ignore: cast_nullable_to_non_nullable
              as List<Task>,
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
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$ProjectImpl implements _Project {
  const _$ProjectImpl(
      {required this.id,
      required this.title,
      final List<Task> tasks = const [],
      this.order = 0.0,
      final List<String> tags = const [],
      this.notes})
      : _tasks = tasks,
        _tags = tags;

  factory _$ProjectImpl.fromJson(Map<String, dynamic> json) =>
      _$$ProjectImplFromJson(json);

  @override
  final String id;
  @override
  final String title;
  final List<Task> _tasks;
  @override
  @JsonKey()
  List<Task> get tasks {
    if (_tasks is EqualUnmodifiableListView) return _tasks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tasks);
  }

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
  String toString() {
    return 'Project(id: $id, title: $title, tasks: $tasks, order: $order, tags: $tags, notes: $notes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$ProjectImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.title, title) || other.title == title) &&
            const DeepCollectionEquality().equals(other._tasks, _tasks) &&
            (identical(other.order, order) || other.order == order) &&
            const DeepCollectionEquality().equals(other._tags, _tags) &&
            (identical(other.notes, notes) || other.notes == notes));
  }

  @JsonKey(ignore: true)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      title,
      const DeepCollectionEquality().hash(_tasks),
      order,
      const DeepCollectionEquality().hash(_tags),
      notes);

  @JsonKey(ignore: true)
  @override
  @pragma('vm:prefer-inline')
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      __$$ProjectImplCopyWithImpl<_$ProjectImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$ProjectImplToJson(
      this,
    );
  }
}

abstract class _Project implements Project {
  const factory _Project(
      {required final String id,
      required final String title,
      final List<Task> tasks,
      final double order,
      final List<String> tags,
      final String? notes}) = _$ProjectImpl;

  factory _Project.fromJson(Map<String, dynamic> json) = _$ProjectImpl.fromJson;

  @override
  String get id;
  @override
  String get title;
  @override
  List<Task> get tasks;
  @override
  double get order;
  @override
  List<String> get tags;
  @override
  String? get notes;
  @override
  @JsonKey(ignore: true)
  _$$ProjectImplCopyWith<_$ProjectImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
