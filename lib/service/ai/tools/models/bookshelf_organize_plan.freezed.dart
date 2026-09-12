// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookshelf_organize_plan.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookshelfOrganizePlan {
  List<BookshelfOrganizePlanGroup> get groups;
  List<BookshelfOrganizePlanBook> get ungroupedBooks;
  List<int> get cleanupGroupIds;
  String? get summary;

  /// Create a copy of BookshelfOrganizePlan
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookshelfOrganizePlanCopyWith<BookshelfOrganizePlan> get copyWith =>
      _$BookshelfOrganizePlanCopyWithImpl<BookshelfOrganizePlan>(
          this as BookshelfOrganizePlan, _$identity);

  /// Serializes this BookshelfOrganizePlan to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookshelfOrganizePlan &&
            const DeepCollectionEquality().equals(other.groups, groups) &&
            const DeepCollectionEquality()
                .equals(other.ungroupedBooks, ungroupedBooks) &&
            const DeepCollectionEquality()
                .equals(other.cleanupGroupIds, cleanupGroupIds) &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(groups),
      const DeepCollectionEquality().hash(ungroupedBooks),
      const DeepCollectionEquality().hash(cleanupGroupIds),
      summary);

  @override
  String toString() {
    return 'BookshelfOrganizePlan(groups: $groups, ungroupedBooks: $ungroupedBooks, cleanupGroupIds: $cleanupGroupIds, summary: $summary)';
  }
}

/// @nodoc
abstract mixin class $BookshelfOrganizePlanCopyWith<$Res> {
  factory $BookshelfOrganizePlanCopyWith(BookshelfOrganizePlan value,
          $Res Function(BookshelfOrganizePlan) _then) =
      _$BookshelfOrganizePlanCopyWithImpl;
  @useResult
  $Res call(
      {List<BookshelfOrganizePlanGroup> groups,
      List<BookshelfOrganizePlanBook> ungroupedBooks,
      List<int> cleanupGroupIds,
      String? summary});
}

/// @nodoc
class _$BookshelfOrganizePlanCopyWithImpl<$Res>
    implements $BookshelfOrganizePlanCopyWith<$Res> {
  _$BookshelfOrganizePlanCopyWithImpl(this._self, this._then);

  final BookshelfOrganizePlan _self;
  final $Res Function(BookshelfOrganizePlan) _then;

  /// Create a copy of BookshelfOrganizePlan
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groups = null,
    Object? ungroupedBooks = null,
    Object? cleanupGroupIds = null,
    Object? summary = freezed,
  }) {
    return _then(_self.copyWith(
      groups: null == groups
          ? _self.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<BookshelfOrganizePlanGroup>,
      ungroupedBooks: null == ungroupedBooks
          ? _self.ungroupedBooks
          : ungroupedBooks // ignore: cast_nullable_to_non_nullable
              as List<BookshelfOrganizePlanBook>,
      cleanupGroupIds: null == cleanupGroupIds
          ? _self.cleanupGroupIds
          : cleanupGroupIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      summary: freezed == summary
          ? _self.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BookshelfOrganizePlan extends BookshelfOrganizePlan {
  const _BookshelfOrganizePlan(
      {final List<BookshelfOrganizePlanGroup> groups =
          const <BookshelfOrganizePlanGroup>[],
      final List<BookshelfOrganizePlanBook> ungroupedBooks =
          const <BookshelfOrganizePlanBook>[],
      final List<int> cleanupGroupIds = const <int>[],
      this.summary})
      : _groups = groups,
        _ungroupedBooks = ungroupedBooks,
        _cleanupGroupIds = cleanupGroupIds,
        super._();
  factory _BookshelfOrganizePlan.fromJson(Map<String, dynamic> json) =>
      _$BookshelfOrganizePlanFromJson(json);

  final List<BookshelfOrganizePlanGroup> _groups;
  @override
  @JsonKey()
  List<BookshelfOrganizePlanGroup> get groups {
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_groups);
  }

  final List<BookshelfOrganizePlanBook> _ungroupedBooks;
  @override
  @JsonKey()
  List<BookshelfOrganizePlanBook> get ungroupedBooks {
    if (_ungroupedBooks is EqualUnmodifiableListView) return _ungroupedBooks;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ungroupedBooks);
  }

  final List<int> _cleanupGroupIds;
  @override
  @JsonKey()
  List<int> get cleanupGroupIds {
    if (_cleanupGroupIds is EqualUnmodifiableListView) return _cleanupGroupIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_cleanupGroupIds);
  }

  @override
  final String? summary;

  /// Create a copy of BookshelfOrganizePlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookshelfOrganizePlanCopyWith<_BookshelfOrganizePlan> get copyWith =>
      __$BookshelfOrganizePlanCopyWithImpl<_BookshelfOrganizePlan>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookshelfOrganizePlanToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookshelfOrganizePlan &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            const DeepCollectionEquality()
                .equals(other._ungroupedBooks, _ungroupedBooks) &&
            const DeepCollectionEquality()
                .equals(other._cleanupGroupIds, _cleanupGroupIds) &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_groups),
      const DeepCollectionEquality().hash(_ungroupedBooks),
      const DeepCollectionEquality().hash(_cleanupGroupIds),
      summary);

  @override
  String toString() {
    return 'BookshelfOrganizePlan(groups: $groups, ungroupedBooks: $ungroupedBooks, cleanupGroupIds: $cleanupGroupIds, summary: $summary)';
  }
}

/// @nodoc
abstract mixin class _$BookshelfOrganizePlanCopyWith<$Res>
    implements $BookshelfOrganizePlanCopyWith<$Res> {
  factory _$BookshelfOrganizePlanCopyWith(_BookshelfOrganizePlan value,
          $Res Function(_BookshelfOrganizePlan) _then) =
      __$BookshelfOrganizePlanCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<BookshelfOrganizePlanGroup> groups,
      List<BookshelfOrganizePlanBook> ungroupedBooks,
      List<int> cleanupGroupIds,
      String? summary});
}

/// @nodoc
class __$BookshelfOrganizePlanCopyWithImpl<$Res>
    implements _$BookshelfOrganizePlanCopyWith<$Res> {
  __$BookshelfOrganizePlanCopyWithImpl(this._self, this._then);

  final _BookshelfOrganizePlan _self;
  final $Res Function(_BookshelfOrganizePlan) _then;

  /// Create a copy of BookshelfOrganizePlan
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? groups = null,
    Object? ungroupedBooks = null,
    Object? cleanupGroupIds = null,
    Object? summary = freezed,
  }) {
    return _then(_BookshelfOrganizePlan(
      groups: null == groups
          ? _self._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<BookshelfOrganizePlanGroup>,
      ungroupedBooks: null == ungroupedBooks
          ? _self._ungroupedBooks
          : ungroupedBooks // ignore: cast_nullable_to_non_nullable
              as List<BookshelfOrganizePlanBook>,
      cleanupGroupIds: null == cleanupGroupIds
          ? _self._cleanupGroupIds
          : cleanupGroupIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
      summary: freezed == summary
          ? _self.summary
          : summary // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

// dart format on
