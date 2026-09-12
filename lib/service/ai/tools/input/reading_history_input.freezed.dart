// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'reading_history_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$ReadingHistoryInput {
  int? get bookId;
  DateTime? get from;
  DateTime? get to;
  int? get limit;

  /// Create a copy of ReadingHistoryInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $ReadingHistoryInputCopyWith<ReadingHistoryInput> get copyWith =>
      _$ReadingHistoryInputCopyWithImpl<ReadingHistoryInput>(
          this as ReadingHistoryInput, _$identity);

  /// Serializes this ReadingHistoryInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is ReadingHistoryInput &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, bookId, from, to, limit);

  @override
  String toString() {
    return 'ReadingHistoryInput(bookId: $bookId, from: $from, to: $to, limit: $limit)';
  }
}

/// @nodoc
abstract mixin class $ReadingHistoryInputCopyWith<$Res> {
  factory $ReadingHistoryInputCopyWith(
          ReadingHistoryInput value, $Res Function(ReadingHistoryInput) _then) =
      _$ReadingHistoryInputCopyWithImpl;
  @useResult
  $Res call({int? bookId, DateTime? from, DateTime? to, int? limit});
}

/// @nodoc
class _$ReadingHistoryInputCopyWithImpl<$Res>
    implements $ReadingHistoryInputCopyWith<$Res> {
  _$ReadingHistoryInputCopyWithImpl(this._self, this._then);

  final ReadingHistoryInput _self;
  final $Res Function(ReadingHistoryInput) _then;

  /// Create a copy of ReadingHistoryInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookId = freezed,
    Object? from = freezed,
    Object? to = freezed,
    Object? limit = freezed,
  }) {
    return _then(_self.copyWith(
      bookId: freezed == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int?,
      from: freezed == from
          ? _self.from
          : from // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      to: freezed == to
          ? _self.to
          : to // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      limit: freezed == limit
          ? _self.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _ReadingHistoryInput extends ReadingHistoryInput {
  const _ReadingHistoryInput({this.bookId, this.from, this.to, this.limit})
      : super._();
  factory _ReadingHistoryInput.fromJson(Map<String, dynamic> json) =>
      _$ReadingHistoryInputFromJson(json);

  @override
  final int? bookId;
  @override
  final DateTime? from;
  @override
  final DateTime? to;
  @override
  final int? limit;

  /// Create a copy of ReadingHistoryInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$ReadingHistoryInputCopyWith<_ReadingHistoryInput> get copyWith =>
      __$ReadingHistoryInputCopyWithImpl<_ReadingHistoryInput>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$ReadingHistoryInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _ReadingHistoryInput &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, bookId, from, to, limit);

  @override
  String toString() {
    return 'ReadingHistoryInput(bookId: $bookId, from: $from, to: $to, limit: $limit)';
  }
}

/// @nodoc
abstract mixin class _$ReadingHistoryInputCopyWith<$Res>
    implements $ReadingHistoryInputCopyWith<$Res> {
  factory _$ReadingHistoryInputCopyWith(_ReadingHistoryInput value,
          $Res Function(_ReadingHistoryInput) _then) =
      __$ReadingHistoryInputCopyWithImpl;
  @override
  @useResult
  $Res call({int? bookId, DateTime? from, DateTime? to, int? limit});
}

/// @nodoc
class __$ReadingHistoryInputCopyWithImpl<$Res>
    implements _$ReadingHistoryInputCopyWith<$Res> {
  __$ReadingHistoryInputCopyWithImpl(this._self, this._then);

  final _ReadingHistoryInput _self;
  final $Res Function(_ReadingHistoryInput) _then;

  /// Create a copy of ReadingHistoryInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bookId = freezed,
    Object? from = freezed,
    Object? to = freezed,
    Object? limit = freezed,
  }) {
    return _then(_ReadingHistoryInput(
      bookId: freezed == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int?,
      from: freezed == from
          ? _self.from
          : from // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      to: freezed == to
          ? _self.to
          : to // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      limit: freezed == limit
          ? _self.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
