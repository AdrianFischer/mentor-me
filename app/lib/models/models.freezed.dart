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
  final List<HabitRecord> _history;
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
  @override
  List<HabitRecord> get history;
  @JsonKey(ignore: true)
  _$$HabitGoalImplCopyWith<_$HabitGoalImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
