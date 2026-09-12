// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookshelf_organize_group_spec.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookshelfOrganizeGroupSpec {
  int get groupId;
  List<int> get bookIds;
  String? get name;
  bool? get createNew;
  String? get renameTo;

  /// Create a copy of BookshelfOrganizeGroupSpec
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookshelfOrganizeGroupSpecCopyWith<BookshelfOrganizeGroupSpec>
      get copyWith =>
          _$BookshelfOrganizeGroupSpecCopyWithImpl<BookshelfOrganizeGroupSpec>(
              this as BookshelfOrganizeGroupSpec, _$identity);

  /// Serializes this BookshelfOrganizeGroupSpec to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookshelfOrganizeGroupSpec &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            const DeepCollectionEquality().equals(other.bookIds, bookIds) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createNew, createNew) ||
                other.createNew == createNew) &&
            (identical(other.renameTo, renameTo) ||
                other.renameTo == renameTo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, groupId,
      const DeepCollectionEquality().hash(bookIds), name, createNew, renameTo);

  @override
  String toString() {
    return 'BookshelfOrganizeGroupSpec(groupId: $groupId, bookIds: $bookIds, name: $name, createNew: $createNew, renameTo: $renameTo)';
  }
}

/// @nodoc
abstract mixin class $BookshelfOrganizeGroupSpecCopyWith<$Res> {
  factory $BookshelfOrganizeGroupSpecCopyWith(BookshelfOrganizeGroupSpec value,
          $Res Function(BookshelfOrganizeGroupSpec) _then) =
      _$BookshelfOrganizeGroupSpecCopyWithImpl;
  @useResult
  $Res call(
      {int groupId,
      List<int> bookIds,
      String? name,
      bool? createNew,
      String? renameTo});
}

/// @nodoc
class _$BookshelfOrganizeGroupSpecCopyWithImpl<$Res>
    implements $BookshelfOrganizeGroupSpecCopyWith<$Res> {
  _$BookshelfOrganizeGroupSpecCopyWithImpl(this._self, this._then);

  final BookshelfOrganizeGroupSpec _self;
  final $Res Function(BookshelfOrganizeGroupSpec) _then;

  /// Create a copy of BookshelfOrganizeGroupSpec
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? bookIds = null,
    Object? name = freezed,
    Object? createNew = freezed,
    Object? renameTo = freezed,
  }) {
    return _then(_self.copyWith(
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as int,
      bookIds: null == bookIds
          ? _self.bookIds
          : bookIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      createNew: freezed == createNew
          ? _self.createNew
          : createNew // ignore: cast_nullable_to_non_nullable
              as bool?,
      renameTo: freezed == renameTo
          ? _self.renameTo
          : renameTo // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BookshelfOrganizeGroupSpec implements BookshelfOrganizeGroupSpec {
  const _BookshelfOrganizeGroupSpec(
      {required this.groupId,
      required final List<int> bookIds,
      this.name,
      this.createNew,
      this.renameTo})
      : _bookIds = bookIds;
  factory _BookshelfOrganizeGroupSpec.fromJson(Map<String, dynamic> json) =>
      _$BookshelfOrganizeGroupSpecFromJson(json);

  @override
  final int groupId;
  final List<int> _bookIds;
  @override
  List<int> get bookIds {
    if (_bookIds is EqualUnmodifiableListView) return _bookIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_bookIds);
  }

  @override
  final String? name;
  @override
  final bool? createNew;
  @override
  final String? renameTo;

  /// Create a copy of BookshelfOrganizeGroupSpec
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookshelfOrganizeGroupSpecCopyWith<_BookshelfOrganizeGroupSpec>
      get copyWith => __$BookshelfOrganizeGroupSpecCopyWithImpl<
          _BookshelfOrganizeGroupSpec>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookshelfOrganizeGroupSpecToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookshelfOrganizeGroupSpec &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            const DeepCollectionEquality().equals(other._bookIds, _bookIds) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.createNew, createNew) ||
                other.createNew == createNew) &&
            (identical(other.renameTo, renameTo) ||
                other.renameTo == renameTo));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, groupId,
      const DeepCollectionEquality().hash(_bookIds), name, createNew, renameTo);

  @override
  String toString() {
    return 'BookshelfOrganizeGroupSpec(groupId: $groupId, bookIds: $bookIds, name: $name, createNew: $createNew, renameTo: $renameTo)';
  }
}

/// @nodoc
abstract mixin class _$BookshelfOrganizeGroupSpecCopyWith<$Res>
    implements $BookshelfOrganizeGroupSpecCopyWith<$Res> {
  factory _$BookshelfOrganizeGroupSpecCopyWith(
          _BookshelfOrganizeGroupSpec value,
          $Res Function(_BookshelfOrganizeGroupSpec) _then) =
      __$BookshelfOrganizeGroupSpecCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int groupId,
      List<int> bookIds,
      String? name,
      bool? createNew,
      String? renameTo});
}

/// @nodoc
class __$BookshelfOrganizeGroupSpecCopyWithImpl<$Res>
    implements _$BookshelfOrganizeGroupSpecCopyWith<$Res> {
  __$BookshelfOrganizeGroupSpecCopyWithImpl(this._self, this._then);

  final _BookshelfOrganizeGroupSpec _self;
  final $Res Function(_BookshelfOrganizeGroupSpec) _then;

  /// Create a copy of BookshelfOrganizeGroupSpec
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? groupId = null,
    Object? bookIds = null,
    Object? name = freezed,
    Object? createNew = freezed,
    Object? renameTo = freezed,
  }) {
    return _then(_BookshelfOrganizeGroupSpec(
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as int,
      bookIds: null == bookIds
          ? _self._bookIds
          : bookIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      name: freezed == name
          ? _self.name
          : name // ignore: cast_nullable_to_non_nullable
              as String?,
      createNew: freezed == createNew
          ? _self.createNew
          : createNew // ignore: cast_nullable_to_non_nullable
              as bool?,
      renameTo: freezed == renameTo
          ? _self.renameTo
          : renameTo // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
