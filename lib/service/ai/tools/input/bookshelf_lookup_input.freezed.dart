// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookshelf_lookup_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookshelfLookupInput {
  String? get query;
  int? get groupId;
  bool get includeDeleted;
  int? get limit;

  /// Create a copy of BookshelfLookupInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookshelfLookupInputCopyWith<BookshelfLookupInput> get copyWith =>
      _$BookshelfLookupInputCopyWithImpl<BookshelfLookupInput>(
          this as BookshelfLookupInput, _$identity);

  /// Serializes this BookshelfLookupInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookshelfLookupInput &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.includeDeleted, includeDeleted) ||
                other.includeDeleted == includeDeleted) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, query, groupId, includeDeleted, limit);

  @override
  String toString() {
    return 'BookshelfLookupInput(query: $query, groupId: $groupId, includeDeleted: $includeDeleted, limit: $limit)';
  }
}

/// @nodoc
abstract mixin class $BookshelfLookupInputCopyWith<$Res> {
  factory $BookshelfLookupInputCopyWith(BookshelfLookupInput value,
          $Res Function(BookshelfLookupInput) _then) =
      _$BookshelfLookupInputCopyWithImpl;
  @useResult
  $Res call({String? query, int? groupId, bool includeDeleted, int? limit});
}

/// @nodoc
class _$BookshelfLookupInputCopyWithImpl<$Res>
    implements $BookshelfLookupInputCopyWith<$Res> {
  _$BookshelfLookupInputCopyWithImpl(this._self, this._then);

  final BookshelfLookupInput _self;
  final $Res Function(BookshelfLookupInput) _then;

  /// Create a copy of BookshelfLookupInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? query = freezed,
    Object? groupId = freezed,
    Object? includeDeleted = null,
    Object? limit = freezed,
  }) {
    return _then(_self.copyWith(
      query: freezed == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
      groupId: freezed == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as int?,
      includeDeleted: null == includeDeleted
          ? _self.includeDeleted
          : includeDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      limit: freezed == limit
          ? _self.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BookshelfLookupInput extends BookshelfLookupInput {
  const _BookshelfLookupInput(
      {this.query, this.groupId, this.includeDeleted = false, this.limit})
      : super._();
  factory _BookshelfLookupInput.fromJson(Map<String, dynamic> json) =>
      _$BookshelfLookupInputFromJson(json);

  @override
  final String? query;
  @override
  final int? groupId;
  @override
  @JsonKey()
  final bool includeDeleted;
  @override
  final int? limit;

  /// Create a copy of BookshelfLookupInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookshelfLookupInputCopyWith<_BookshelfLookupInput> get copyWith =>
      __$BookshelfLookupInputCopyWithImpl<_BookshelfLookupInput>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookshelfLookupInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookshelfLookupInput &&
            (identical(other.query, query) || other.query == query) &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            (identical(other.includeDeleted, includeDeleted) ||
                other.includeDeleted == includeDeleted) &&
            (identical(other.limit, limit) || other.limit == limit));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, query, groupId, includeDeleted, limit);

  @override
  String toString() {
    return 'BookshelfLookupInput(query: $query, groupId: $groupId, includeDeleted: $includeDeleted, limit: $limit)';
  }
}

/// @nodoc
abstract mixin class _$BookshelfLookupInputCopyWith<$Res>
    implements $BookshelfLookupInputCopyWith<$Res> {
  factory _$BookshelfLookupInputCopyWith(_BookshelfLookupInput value,
          $Res Function(_BookshelfLookupInput) _then) =
      __$BookshelfLookupInputCopyWithImpl;
  @override
  @useResult
  $Res call({String? query, int? groupId, bool includeDeleted, int? limit});
}

/// @nodoc
class __$BookshelfLookupInputCopyWithImpl<$Res>
    implements _$BookshelfLookupInputCopyWith<$Res> {
  __$BookshelfLookupInputCopyWithImpl(this._self, this._then);

  final _BookshelfLookupInput _self;
  final $Res Function(_BookshelfLookupInput) _then;

  /// Create a copy of BookshelfLookupInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? query = freezed,
    Object? groupId = freezed,
    Object? includeDeleted = null,
    Object? limit = freezed,
  }) {
    return _then(_BookshelfLookupInput(
      query: freezed == query
          ? _self.query
          : query // ignore: cast_nullable_to_non_nullable
              as String?,
      groupId: freezed == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as int?,
      includeDeleted: null == includeDeleted
          ? _self.includeDeleted
          : includeDeleted // ignore: cast_nullable_to_non_nullable
              as bool,
      limit: freezed == limit
          ? _self.limit
          : limit // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
