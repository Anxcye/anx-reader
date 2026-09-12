// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookshelf_organize_plan_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookshelfOrganizePlanGroup {
  int get groupId;
  List<BookshelfOrganizePlanBook> get books;
  bool get createNew;
  String? get currentName;
  String? get proposedName;

  /// Create a copy of BookshelfOrganizePlanGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookshelfOrganizePlanGroupCopyWith<BookshelfOrganizePlanGroup>
      get copyWith =>
          _$BookshelfOrganizePlanGroupCopyWithImpl<BookshelfOrganizePlanGroup>(
              this as BookshelfOrganizePlanGroup, _$identity);

  /// Serializes this BookshelfOrganizePlanGroup to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookshelfOrganizePlanGroup &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            const DeepCollectionEquality().equals(other.books, books) &&
            (identical(other.createNew, createNew) ||
                other.createNew == createNew) &&
            (identical(other.currentName, currentName) ||
                other.currentName == currentName) &&
            (identical(other.proposedName, proposedName) ||
                other.proposedName == proposedName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      groupId,
      const DeepCollectionEquality().hash(books),
      createNew,
      currentName,
      proposedName);

  @override
  String toString() {
    return 'BookshelfOrganizePlanGroup(groupId: $groupId, books: $books, createNew: $createNew, currentName: $currentName, proposedName: $proposedName)';
  }
}

/// @nodoc
abstract mixin class $BookshelfOrganizePlanGroupCopyWith<$Res> {
  factory $BookshelfOrganizePlanGroupCopyWith(BookshelfOrganizePlanGroup value,
          $Res Function(BookshelfOrganizePlanGroup) _then) =
      _$BookshelfOrganizePlanGroupCopyWithImpl;
  @useResult
  $Res call(
      {int groupId,
      List<BookshelfOrganizePlanBook> books,
      bool createNew,
      String? currentName,
      String? proposedName});
}

/// @nodoc
class _$BookshelfOrganizePlanGroupCopyWithImpl<$Res>
    implements $BookshelfOrganizePlanGroupCopyWith<$Res> {
  _$BookshelfOrganizePlanGroupCopyWithImpl(this._self, this._then);

  final BookshelfOrganizePlanGroup _self;
  final $Res Function(BookshelfOrganizePlanGroup) _then;

  /// Create a copy of BookshelfOrganizePlanGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groupId = null,
    Object? books = null,
    Object? createNew = null,
    Object? currentName = freezed,
    Object? proposedName = freezed,
  }) {
    return _then(_self.copyWith(
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as int,
      books: null == books
          ? _self.books
          : books // ignore: cast_nullable_to_non_nullable
              as List<BookshelfOrganizePlanBook>,
      createNew: null == createNew
          ? _self.createNew
          : createNew // ignore: cast_nullable_to_non_nullable
              as bool,
      currentName: freezed == currentName
          ? _self.currentName
          : currentName // ignore: cast_nullable_to_non_nullable
              as String?,
      proposedName: freezed == proposedName
          ? _self.proposedName
          : proposedName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BookshelfOrganizePlanGroup extends BookshelfOrganizePlanGroup {
  const _BookshelfOrganizePlanGroup(
      {required this.groupId,
      final List<BookshelfOrganizePlanBook> books =
          const <BookshelfOrganizePlanBook>[],
      required this.createNew,
      this.currentName,
      this.proposedName})
      : _books = books,
        super._();
  factory _BookshelfOrganizePlanGroup.fromJson(Map<String, dynamic> json) =>
      _$BookshelfOrganizePlanGroupFromJson(json);

  @override
  final int groupId;
  final List<BookshelfOrganizePlanBook> _books;
  @override
  @JsonKey()
  List<BookshelfOrganizePlanBook> get books {
    if (_books is EqualUnmodifiableListView) return _books;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_books);
  }

  @override
  final bool createNew;
  @override
  final String? currentName;
  @override
  final String? proposedName;

  /// Create a copy of BookshelfOrganizePlanGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookshelfOrganizePlanGroupCopyWith<_BookshelfOrganizePlanGroup>
      get copyWith => __$BookshelfOrganizePlanGroupCopyWithImpl<
          _BookshelfOrganizePlanGroup>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookshelfOrganizePlanGroupToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookshelfOrganizePlanGroup &&
            (identical(other.groupId, groupId) || other.groupId == groupId) &&
            const DeepCollectionEquality().equals(other._books, _books) &&
            (identical(other.createNew, createNew) ||
                other.createNew == createNew) &&
            (identical(other.currentName, currentName) ||
                other.currentName == currentName) &&
            (identical(other.proposedName, proposedName) ||
                other.proposedName == proposedName));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      groupId,
      const DeepCollectionEquality().hash(_books),
      createNew,
      currentName,
      proposedName);

  @override
  String toString() {
    return 'BookshelfOrganizePlanGroup(groupId: $groupId, books: $books, createNew: $createNew, currentName: $currentName, proposedName: $proposedName)';
  }
}

/// @nodoc
abstract mixin class _$BookshelfOrganizePlanGroupCopyWith<$Res>
    implements $BookshelfOrganizePlanGroupCopyWith<$Res> {
  factory _$BookshelfOrganizePlanGroupCopyWith(
          _BookshelfOrganizePlanGroup value,
          $Res Function(_BookshelfOrganizePlanGroup) _then) =
      __$BookshelfOrganizePlanGroupCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int groupId,
      List<BookshelfOrganizePlanBook> books,
      bool createNew,
      String? currentName,
      String? proposedName});
}

/// @nodoc
class __$BookshelfOrganizePlanGroupCopyWithImpl<$Res>
    implements _$BookshelfOrganizePlanGroupCopyWith<$Res> {
  __$BookshelfOrganizePlanGroupCopyWithImpl(this._self, this._then);

  final _BookshelfOrganizePlanGroup _self;
  final $Res Function(_BookshelfOrganizePlanGroup) _then;

  /// Create a copy of BookshelfOrganizePlanGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? groupId = null,
    Object? books = null,
    Object? createNew = null,
    Object? currentName = freezed,
    Object? proposedName = freezed,
  }) {
    return _then(_BookshelfOrganizePlanGroup(
      groupId: null == groupId
          ? _self.groupId
          : groupId // ignore: cast_nullable_to_non_nullable
              as int,
      books: null == books
          ? _self._books
          : books // ignore: cast_nullable_to_non_nullable
              as List<BookshelfOrganizePlanBook>,
      createNew: null == createNew
          ? _self.createNew
          : createNew // ignore: cast_nullable_to_non_nullable
              as bool,
      currentName: freezed == currentName
          ? _self.currentName
          : currentName // ignore: cast_nullable_to_non_nullable
              as String?,
      proposedName: freezed == proposedName
          ? _self.proposedName
          : proposedName // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
