// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_result_data.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchResultData {
  List<Book> get books;
  List<SearchNoteGroup> get noteGroups;

  /// Create a copy of SearchResultData
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SearchResultDataCopyWith<SearchResultData> get copyWith =>
      _$SearchResultDataCopyWithImpl<SearchResultData>(
          this as SearchResultData, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SearchResultData &&
            const DeepCollectionEquality().equals(other.books, books) &&
            const DeepCollectionEquality()
                .equals(other.noteGroups, noteGroups));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(books),
      const DeepCollectionEquality().hash(noteGroups));

  @override
  String toString() {
    return 'SearchResultData(books: $books, noteGroups: $noteGroups)';
  }
}

/// @nodoc
abstract mixin class $SearchResultDataCopyWith<$Res> {
  factory $SearchResultDataCopyWith(
          SearchResultData value, $Res Function(SearchResultData) _then) =
      _$SearchResultDataCopyWithImpl;
  @useResult
  $Res call({List<Book> books, List<SearchNoteGroup> noteGroups});
}

/// @nodoc
class _$SearchResultDataCopyWithImpl<$Res>
    implements $SearchResultDataCopyWith<$Res> {
  _$SearchResultDataCopyWithImpl(this._self, this._then);

  final SearchResultData _self;
  final $Res Function(SearchResultData) _then;

  /// Create a copy of SearchResultData
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? books = null,
    Object? noteGroups = null,
  }) {
    return _then(_self.copyWith(
      books: null == books
          ? _self.books
          : books // ignore: cast_nullable_to_non_nullable
              as List<Book>,
      noteGroups: null == noteGroups
          ? _self.noteGroups
          : noteGroups // ignore: cast_nullable_to_non_nullable
              as List<SearchNoteGroup>,
    ));
  }
}

/// @nodoc

class _SearchResultData implements SearchResultData {
  const _SearchResultData(
      {required final List<Book> books,
      required final List<SearchNoteGroup> noteGroups})
      : _books = books,
        _noteGroups = noteGroups;

  final List<Book> _books;
  @override
  List<Book> get books {
    if (_books is EqualUnmodifiableListView) return _books;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_books);
  }

  final List<SearchNoteGroup> _noteGroups;
  @override
  List<SearchNoteGroup> get noteGroups {
    if (_noteGroups is EqualUnmodifiableListView) return _noteGroups;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_noteGroups);
  }

  /// Create a copy of SearchResultData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SearchResultDataCopyWith<_SearchResultData> get copyWith =>
      __$SearchResultDataCopyWithImpl<_SearchResultData>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SearchResultData &&
            const DeepCollectionEquality().equals(other._books, _books) &&
            const DeepCollectionEquality()
                .equals(other._noteGroups, _noteGroups));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType,
      const DeepCollectionEquality().hash(_books),
      const DeepCollectionEquality().hash(_noteGroups));

  @override
  String toString() {
    return 'SearchResultData(books: $books, noteGroups: $noteGroups)';
  }
}

/// @nodoc
abstract mixin class _$SearchResultDataCopyWith<$Res>
    implements $SearchResultDataCopyWith<$Res> {
  factory _$SearchResultDataCopyWith(
          _SearchResultData value, $Res Function(_SearchResultData) _then) =
      __$SearchResultDataCopyWithImpl;
  @override
  @useResult
  $Res call({List<Book> books, List<SearchNoteGroup> noteGroups});
}

/// @nodoc
class __$SearchResultDataCopyWithImpl<$Res>
    implements _$SearchResultDataCopyWith<$Res> {
  __$SearchResultDataCopyWithImpl(this._self, this._then);

  final _SearchResultData _self;
  final $Res Function(_SearchResultData) _then;

  /// Create a copy of SearchResultData
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? books = null,
    Object? noteGroups = null,
  }) {
    return _then(_SearchResultData(
      books: null == books
          ? _self._books
          : books // ignore: cast_nullable_to_non_nullable
              as List<Book>,
      noteGroups: null == noteGroups
          ? _self._noteGroups
          : noteGroups // ignore: cast_nullable_to_non_nullable
              as List<SearchNoteGroup>,
    ));
  }
}

// dart format on
