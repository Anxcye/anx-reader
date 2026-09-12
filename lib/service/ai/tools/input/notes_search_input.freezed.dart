// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'notes_search_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$NotesSearchInput {
  String? get keyword;
  int? get bookId;
  DateTime? get from;
  DateTime? get to;
  int? get limit;

  /// Create a copy of NotesSearchInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $NotesSearchInputCopyWith<NotesSearchInput> get copyWith =>
      _$NotesSearchInputCopyWithImpl<NotesSearchInput>(
          this as NotesSearchInput, _$identity);

  /// Serializes this NotesSearchInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is NotesSearchInput &&
            (identical(other.keyword, keyword) || other.keyword == keyword) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, keyword, bookId, from, to, limit);

  @override
  String toString() {
    return 'NotesSearchInput(keyword: $keyword, bookId: $bookId, from: $from, to: $to, limit: $limit)';
  }
}

/// @nodoc
abstract mixin class $NotesSearchInputCopyWith<$Res> {
  factory $NotesSearchInputCopyWith(
          NotesSearchInput value, $Res Function(NotesSearchInput) _then) =
      _$NotesSearchInputCopyWithImpl;
  @useResult
  $Res call(
      {String? keyword, int? bookId, DateTime? from, DateTime? to, int? limit});
}

/// @nodoc
class _$NotesSearchInputCopyWithImpl<$Res>
    implements $NotesSearchInputCopyWith<$Res> {
  _$NotesSearchInputCopyWithImpl(this._self, this._then);

  final NotesSearchInput _self;
  final $Res Function(NotesSearchInput) _then;

  /// Create a copy of NotesSearchInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? keyword = freezed,
    Object? bookId = freezed,
    Object? from = freezed,
    Object? to = freezed,
    Object? limit = freezed,
  }) {
    return _then(_self.copyWith(
      keyword: freezed == keyword
          ? _self.keyword
          : keyword // ignore: cast_nullable_to_non_nullable
              as String?,
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
class _NotesSearchInput extends NotesSearchInput {
  const _NotesSearchInput(
      {this.keyword, this.bookId, this.from, this.to, this.limit})
      : super._();
  factory _NotesSearchInput.fromJson(Map<String, dynamic> json) =>
      _$NotesSearchInputFromJson(json);

  @override
  final String? keyword;
  @override
  final int? bookId;
  @override
  final DateTime? from;
  @override
  final DateTime? to;
  @override
  final int? limit;

  /// Create a copy of NotesSearchInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$NotesSearchInputCopyWith<_NotesSearchInput> get copyWith =>
      __$NotesSearchInputCopyWithImpl<_NotesSearchInput>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$NotesSearchInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _NotesSearchInput &&
            (identical(other.keyword, keyword) || other.keyword == keyword) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.from, from) || other.from == from) &&
            (identical(other.to, to) || other.to == to) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, keyword, bookId, from, to, limit);

  @override
  String toString() {
    return 'NotesSearchInput(keyword: $keyword, bookId: $bookId, from: $from, to: $to, limit: $limit)';
  }
}

/// @nodoc
abstract mixin class _$NotesSearchInputCopyWith<$Res>
    implements $NotesSearchInputCopyWith<$Res> {
  factory _$NotesSearchInputCopyWith(
          _NotesSearchInput value, $Res Function(_NotesSearchInput) _then) =
      __$NotesSearchInputCopyWithImpl;
  @override
  @useResult
  $Res call(
      {String? keyword, int? bookId, DateTime? from, DateTime? to, int? limit});
}

/// @nodoc
class __$NotesSearchInputCopyWithImpl<$Res>
    implements _$NotesSearchInputCopyWith<$Res> {
  __$NotesSearchInputCopyWithImpl(this._self, this._then);

  final _NotesSearchInput _self;
  final $Res Function(_NotesSearchInput) _then;

  /// Create a copy of NotesSearchInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? keyword = freezed,
    Object? bookId = freezed,
    Object? from = freezed,
    Object? to = freezed,
    Object? limit = freezed,
  }) {
    return _then(_NotesSearchInput(
      keyword: freezed == keyword
          ? _self.keyword
          : keyword // ignore: cast_nullable_to_non_nullable
              as String?,
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
