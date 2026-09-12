// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'statistic_data_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$StatisticDataModel {
  ChartMode get mode;
  bool get isSelectingDay;
  DateTime get date;
  List<int> get readingTime;
  List<String> get xLabels;
  List<Map<Book, int>> get bookReadingTime;

  /// Create a copy of StatisticDataModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $StatisticDataModelCopyWith<StatisticDataModel> get copyWith =>
      _$StatisticDataModelCopyWithImpl<StatisticDataModel>(
          this as StatisticDataModel, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is StatisticDataModel &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.isSelectingDay, isSelectingDay) ||
                other.isSelectingDay == isSelectingDay) &&
            (identical(other.date, date) || other.date == date) &&
            const DeepCollectionEquality()
                .equals(other.readingTime, readingTime) &&
            const DeepCollectionEquality().equals(other.xLabels, xLabels) &&
            const DeepCollectionEquality()
                .equals(other.bookReadingTime, bookReadingTime));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      mode,
      isSelectingDay,
      date,
      const DeepCollectionEquality().hash(readingTime),
      const DeepCollectionEquality().hash(xLabels),
      const DeepCollectionEquality().hash(bookReadingTime));

  @override
  String toString() {
    return 'StatisticDataModel(mode: $mode, isSelectingDay: $isSelectingDay, date: $date, readingTime: $readingTime, xLabels: $xLabels, bookReadingTime: $bookReadingTime)';
  }
}

/// @nodoc
abstract mixin class $StatisticDataModelCopyWith<$Res> {
  factory $StatisticDataModelCopyWith(
          StatisticDataModel value, $Res Function(StatisticDataModel) _then) =
      _$StatisticDataModelCopyWithImpl;
  @useResult
  $Res call(
      {ChartMode mode,
      bool isSelectingDay,
      DateTime date,
      List<int> readingTime,
      List<String> xLabels,
      List<Map<Book, int>> bookReadingTime});
}

/// @nodoc
class _$StatisticDataModelCopyWithImpl<$Res>
    implements $StatisticDataModelCopyWith<$Res> {
  _$StatisticDataModelCopyWithImpl(this._self, this._then);

  final StatisticDataModel _self;
  final $Res Function(StatisticDataModel) _then;

  /// Create a copy of StatisticDataModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? mode = null,
    Object? isSelectingDay = null,
    Object? date = null,
    Object? readingTime = null,
    Object? xLabels = null,
    Object? bookReadingTime = null,
  }) {
    return _then(_self.copyWith(
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as ChartMode,
      isSelectingDay: null == isSelectingDay
          ? _self.isSelectingDay
          : isSelectingDay // ignore: cast_nullable_to_non_nullable
              as bool,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      readingTime: null == readingTime
          ? _self.readingTime
          : readingTime // ignore: cast_nullable_to_non_nullable
              as List<int>,
      xLabels: null == xLabels
          ? _self.xLabels
          : xLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bookReadingTime: null == bookReadingTime
          ? _self.bookReadingTime
          : bookReadingTime // ignore: cast_nullable_to_non_nullable
              as List<Map<Book, int>>,
    ));
  }
}

/// @nodoc

class _StatisticDataModel implements StatisticDataModel {
  const _StatisticDataModel(
      {required this.mode,
      required this.isSelectingDay,
      required this.date,
      required final List<int> readingTime,
      required final List<String> xLabels,
      required final List<Map<Book, int>> bookReadingTime})
      : _readingTime = readingTime,
        _xLabels = xLabels,
        _bookReadingTime = bookReadingTime;

  @override
  final ChartMode mode;
  @override
  final bool isSelectingDay;
  @override
  final DateTime date;
  final List<int> _readingTime;
  @override
  List<int> get readingTime {
    if (_readingTime is EqualUnmodifiableListView) return _readingTime;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_readingTime);
  }

  final List<String> _xLabels;
  @override
  List<String> get xLabels {
    if (_xLabels is EqualUnmodifiableListView) return _xLabels;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_xLabels);
  }

  final List<Map<Book, int>> _bookReadingTime;
  @override
  List<Map<Book, int>> get bookReadingTime {
    if (_bookReadingTime is EqualUnmodifiableListView) return _bookReadingTime;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookReadingTime);
  }

  /// Create a copy of StatisticDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$StatisticDataModelCopyWith<_StatisticDataModel> get copyWith =>
      __$StatisticDataModelCopyWithImpl<_StatisticDataModel>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _StatisticDataModel &&
            (identical(other.mode, mode) || other.mode == mode) &&
            (identical(other.isSelectingDay, isSelectingDay) ||
                other.isSelectingDay == isSelectingDay) &&
            (identical(other.date, date) || other.date == date) &&
            const DeepCollectionEquality()
                .equals(other._readingTime, _readingTime) &&
            const DeepCollectionEquality().equals(other._xLabels, _xLabels) &&
            const DeepCollectionEquality()
                .equals(other._bookReadingTime, _bookReadingTime));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      mode,
      isSelectingDay,
      date,
      const DeepCollectionEquality().hash(_readingTime),
      const DeepCollectionEquality().hash(_xLabels),
      const DeepCollectionEquality().hash(_bookReadingTime));

  @override
  String toString() {
    return 'StatisticDataModel(mode: $mode, isSelectingDay: $isSelectingDay, date: $date, readingTime: $readingTime, xLabels: $xLabels, bookReadingTime: $bookReadingTime)';
  }
}

/// @nodoc
abstract mixin class _$StatisticDataModelCopyWith<$Res>
    implements $StatisticDataModelCopyWith<$Res> {
  factory _$StatisticDataModelCopyWith(
          _StatisticDataModel value, $Res Function(_StatisticDataModel) _then) =
      __$StatisticDataModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {ChartMode mode,
      bool isSelectingDay,
      DateTime date,
      List<int> readingTime,
      List<String> xLabels,
      List<Map<Book, int>> bookReadingTime});
}

/// @nodoc
class __$StatisticDataModelCopyWithImpl<$Res>
    implements _$StatisticDataModelCopyWith<$Res> {
  __$StatisticDataModelCopyWithImpl(this._self, this._then);

  final _StatisticDataModel _self;
  final $Res Function(_StatisticDataModel) _then;

  /// Create a copy of StatisticDataModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? mode = null,
    Object? isSelectingDay = null,
    Object? date = null,
    Object? readingTime = null,
    Object? xLabels = null,
    Object? bookReadingTime = null,
  }) {
    return _then(_StatisticDataModel(
      mode: null == mode
          ? _self.mode
          : mode // ignore: cast_nullable_to_non_nullable
              as ChartMode,
      isSelectingDay: null == isSelectingDay
          ? _self.isSelectingDay
          : isSelectingDay // ignore: cast_nullable_to_non_nullable
              as bool,
      date: null == date
          ? _self.date
          : date // ignore: cast_nullable_to_non_nullable
              as DateTime,
      readingTime: null == readingTime
          ? _self._readingTime
          : readingTime // ignore: cast_nullable_to_non_nullable
              as List<int>,
      xLabels: null == xLabels
          ? _self._xLabels
          : xLabels // ignore: cast_nullable_to_non_nullable
              as List<String>,
      bookReadingTime: null == bookReadingTime
          ? _self._bookReadingTime
          : bookReadingTime // ignore: cast_nullable_to_non_nullable
              as List<Map<Book, int>>,
    ));
  }
}

// dart format on
