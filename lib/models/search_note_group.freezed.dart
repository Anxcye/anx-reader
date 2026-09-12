// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'search_note_group.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$SearchNoteGroup {
  Book get book;
  List<BookNote> get notes;

  /// Create a copy of SearchNoteGroup
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $SearchNoteGroupCopyWith<SearchNoteGroup> get copyWith =>
      _$SearchNoteGroupCopyWithImpl<SearchNoteGroup>(
          this as SearchNoteGroup, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is SearchNoteGroup &&
            (identical(other.book, book) || other.book == book) &&
            const DeepCollectionEquality().equals(other.notes, notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, book, const DeepCollectionEquality().hash(notes));

  @override
  String toString() {
    return 'SearchNoteGroup(book: $book, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class $SearchNoteGroupCopyWith<$Res> {
  factory $SearchNoteGroupCopyWith(
          SearchNoteGroup value, $Res Function(SearchNoteGroup) _then) =
      _$SearchNoteGroupCopyWithImpl;
  @useResult
  $Res call({Book book, List<BookNote> notes});
}

/// @nodoc
class _$SearchNoteGroupCopyWithImpl<$Res>
    implements $SearchNoteGroupCopyWith<$Res> {
  _$SearchNoteGroupCopyWithImpl(this._self, this._then);

  final SearchNoteGroup _self;
  final $Res Function(SearchNoteGroup) _then;

  /// Create a copy of SearchNoteGroup
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? book = null,
    Object? notes = null,
  }) {
    return _then(_self.copyWith(
      book: null == book
          ? _self.book
          : book // ignore: cast_nullable_to_non_nullable
              as Book,
      notes: null == notes
          ? _self.notes
          : notes // ignore: cast_nullable_to_non_nullable
              as List<BookNote>,
    ));
  }
}

/// @nodoc

class _SearchNoteGroup implements SearchNoteGroup {
  const _SearchNoteGroup(
      {required this.book, required final List<BookNote> notes})
      : _notes = notes;

  @override
  final Book book;
  final List<BookNote> _notes;
  @override
  List<BookNote> get notes {
    if (_notes is EqualUnmodifiableListView) return _notes;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_notes);
  }

  /// Create a copy of SearchNoteGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$SearchNoteGroupCopyWith<_SearchNoteGroup> get copyWith =>
      __$SearchNoteGroupCopyWithImpl<_SearchNoteGroup>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _SearchNoteGroup &&
            (identical(other.book, book) || other.book == book) &&
            const DeepCollectionEquality().equals(other._notes, _notes));
  }

  @override
  int get hashCode => Object.hash(
      runtimeType, book, const DeepCollectionEquality().hash(_notes));

  @override
  String toString() {
    return 'SearchNoteGroup(book: $book, notes: $notes)';
  }
}

/// @nodoc
abstract mixin class _$SearchNoteGroupCopyWith<$Res>
    implements $SearchNoteGroupCopyWith<$Res> {
  factory _$SearchNoteGroupCopyWith(
          _SearchNoteGroup value, $Res Function(_SearchNoteGroup) _then) =
      __$SearchNoteGroupCopyWithImpl;
  @override
  @useResult
  $Res call({Book book, List<BookNote> notes});
}

/// @nodoc
class __$SearchNoteGroupCopyWithImpl<$Res>
    implements _$SearchNoteGroupCopyWith<$Res> {
  __$SearchNoteGroupCopyWithImpl(this._self, this._then);

  final _SearchNoteGroup _self;
  final $Res Function(_SearchNoteGroup) _then;

  /// Create a copy of SearchNoteGroup
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? book = null,
    Object? notes = null,
  }) {
    return _then(_SearchNoteGroup(
      book: null == book
          ? _self.book
          : book // ignore: cast_nullable_to_non_nullable
              as Book,
      notes: null == notes
          ? _self._notes
          : notes // ignore: cast_nullable_to_non_nullable
              as List<BookNote>,
    ));
  }
}

// dart format on
