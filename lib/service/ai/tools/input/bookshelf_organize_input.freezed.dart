// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookshelf_organize_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookshelfOrganizeInput {
  List<BookshelfOrganizeGroupSpec> get groups;
  List<int> get ungroupedBookIds;
  List<int> get cleanupGroupIds;
  String? get summary;

  /// Create a copy of BookshelfOrganizeInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookshelfOrganizeInputCopyWith<BookshelfOrganizeInput> get copyWith =>
      _$BookshelfOrganizeInputCopyWithImpl<BookshelfOrganizeInput>(
          this as BookshelfOrganizeInput, _$identity);

  /// Serializes this BookshelfOrganizeInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookshelfOrganizeInput &&
            const DeepCollectionEquality().equals(other.groups, groups) &&
            const DeepCollectionEquality()
                .equals(other.ungroupedBookIds, ungroupedBookIds) &&
            const DeepCollectionEquality()
                .equals(other.cleanupGroupIds, cleanupGroupIds) &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(groups),
      const DeepCollectionEquality().hash(ungroupedBookIds),
      const DeepCollectionEquality().hash(cleanupGroupIds),
      summary);

  @override
  String toString() {
    return 'BookshelfOrganizeInput(groups: $groups, ungroupedBookIds: $ungroupedBookIds, cleanupGroupIds: $cleanupGroupIds, summary: $summary)';
  }
}

/// @nodoc
abstract mixin class $BookshelfOrganizeInputCopyWith<$Res> {
  factory $BookshelfOrganizeInputCopyWith(BookshelfOrganizeInput value,
          $Res Function(BookshelfOrganizeInput) _then) =
      _$BookshelfOrganizeInputCopyWithImpl;
  @useResult
  $Res call(
      {List<BookshelfOrganizeGroupSpec> groups,
      List<int> ungroupedBookIds,
      List<int> cleanupGroupIds,
      String? summary});
}

/// @nodoc
class _$BookshelfOrganizeInputCopyWithImpl<$Res>
    implements $BookshelfOrganizeInputCopyWith<$Res> {
  _$BookshelfOrganizeInputCopyWithImpl(this._self, this._then);

  final BookshelfOrganizeInput _self;
  final $Res Function(BookshelfOrganizeInput) _then;

  /// Create a copy of BookshelfOrganizeInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? groups = null,
    Object? ungroupedBookIds = null,
    Object? cleanupGroupIds = null,
    Object? summary = freezed,
  }) {
    return _then(_self.copyWith(
      groups: null == groups
          ? _self.groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<BookshelfOrganizeGroupSpec>,
      ungroupedBookIds: null == ungroupedBookIds
          ? _self.ungroupedBookIds
          : ungroupedBookIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
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
class _BookshelfOrganizeInput extends BookshelfOrganizeInput {
  const _BookshelfOrganizeInput(
      {required final List<BookshelfOrganizeGroupSpec> groups,
      final List<int> ungroupedBookIds = const <int>[],
      final List<int> cleanupGroupIds = const <int>[],
      this.summary})
      : _groups = groups,
        _ungroupedBookIds = ungroupedBookIds,
        _cleanupGroupIds = cleanupGroupIds,
        super._();
  factory _BookshelfOrganizeInput.fromJson(Map<String, dynamic> json) =>
      _$BookshelfOrganizeInputFromJson(json);

  final List<BookshelfOrganizeGroupSpec> _groups;
  @override
  List<BookshelfOrganizeGroupSpec> get groups {
    if (_groups is EqualUnmodifiableListView) return _groups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_groups);
  }

  final List<int> _ungroupedBookIds;
  @override
  @JsonKey()
  List<int> get ungroupedBookIds {
    if (_ungroupedBookIds is EqualUnmodifiableListView)
      return _ungroupedBookIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ungroupedBookIds);
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

  /// Create a copy of BookshelfOrganizeInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookshelfOrganizeInputCopyWith<_BookshelfOrganizeInput> get copyWith =>
      __$BookshelfOrganizeInputCopyWithImpl<_BookshelfOrganizeInput>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookshelfOrganizeInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookshelfOrganizeInput &&
            const DeepCollectionEquality().equals(other._groups, _groups) &&
            const DeepCollectionEquality()
                .equals(other._ungroupedBookIds, _ungroupedBookIds) &&
            const DeepCollectionEquality()
                .equals(other._cleanupGroupIds, _cleanupGroupIds) &&
            (identical(other.summary, summary) || other.summary == summary));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_groups),
      const DeepCollectionEquality().hash(_ungroupedBookIds),
      const DeepCollectionEquality().hash(_cleanupGroupIds),
      summary);

  @override
  String toString() {
    return 'BookshelfOrganizeInput(groups: $groups, ungroupedBookIds: $ungroupedBookIds, cleanupGroupIds: $cleanupGroupIds, summary: $summary)';
  }
}

/// @nodoc
abstract mixin class _$BookshelfOrganizeInputCopyWith<$Res>
    implements $BookshelfOrganizeInputCopyWith<$Res> {
  factory _$BookshelfOrganizeInputCopyWith(_BookshelfOrganizeInput value,
          $Res Function(_BookshelfOrganizeInput) _then) =
      __$BookshelfOrganizeInputCopyWithImpl;
  @override
  @useResult
  $Res call(
      {List<BookshelfOrganizeGroupSpec> groups,
      List<int> ungroupedBookIds,
      List<int> cleanupGroupIds,
      String? summary});
}

/// @nodoc
class __$BookshelfOrganizeInputCopyWithImpl<$Res>
    implements _$BookshelfOrganizeInputCopyWith<$Res> {
  __$BookshelfOrganizeInputCopyWithImpl(this._self, this._then);

  final _BookshelfOrganizeInput _self;
  final $Res Function(_BookshelfOrganizeInput) _then;

  /// Create a copy of BookshelfOrganizeInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? groups = null,
    Object? ungroupedBookIds = null,
    Object? cleanupGroupIds = null,
    Object? summary = freezed,
  }) {
    return _then(_BookshelfOrganizeInput(
      groups: null == groups
          ? _self._groups
          : groups // ignore: cast_nullable_to_non_nullable
              as List<BookshelfOrganizeGroupSpec>,
      ungroupedBookIds: null == ungroupedBookIds
          ? _self._ungroupedBookIds
          : ungroupedBookIds // ignore: cast_nullable_to_non_nullable
              as List<int>,
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
