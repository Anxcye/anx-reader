// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'current_notes_detail.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CurrentNotesDetail {
  Book get book;
  int get numberOfNotes;

  /// Create a copy of CurrentNotesDetail
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CurrentNotesDetailCopyWith<CurrentNotesDetail> get copyWith =>
      _$CurrentNotesDetailCopyWithImpl<CurrentNotesDetail>(
          this as CurrentNotesDetail, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CurrentNotesDetail &&
            (identical(other.book, book) || other.book == book) &&
            (identical(other.numberOfNotes, numberOfNotes) ||
                other.numberOfNotes == numberOfNotes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, book, numberOfNotes);

  @override
  String toString() {
    return 'CurrentNotesDetail(book: $book, numberOfNotes: $numberOfNotes)';
  }
}

/// @nodoc
abstract mixin class $CurrentNotesDetailCopyWith<$Res> {
  factory $CurrentNotesDetailCopyWith(
          CurrentNotesDetail value, $Res Function(CurrentNotesDetail) _then) =
      _$CurrentNotesDetailCopyWithImpl;
  @useResult
  $Res call({Book book, int numberOfNotes});
}

/// @nodoc
class _$CurrentNotesDetailCopyWithImpl<$Res>
    implements $CurrentNotesDetailCopyWith<$Res> {
  _$CurrentNotesDetailCopyWithImpl(this._self, this._then);

  final CurrentNotesDetail _self;
  final $Res Function(CurrentNotesDetail) _then;

  /// Create a copy of CurrentNotesDetail
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? book = null,
    Object? numberOfNotes = null,
  }) {
    return _then(_self.copyWith(
      book: null == book
          ? _self.book
          : book // ignore: cast_nullable_to_non_nullable
              as Book,
      numberOfNotes: null == numberOfNotes
          ? _self.numberOfNotes
          : numberOfNotes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

/// @nodoc

class _CurrentNotesDetail implements CurrentNotesDetail {
  const _CurrentNotesDetail({required this.book, required this.numberOfNotes});

  @override
  final Book book;
  @override
  final int numberOfNotes;

  /// Create a copy of CurrentNotesDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CurrentNotesDetailCopyWith<_CurrentNotesDetail> get copyWith =>
      __$CurrentNotesDetailCopyWithImpl<_CurrentNotesDetail>(this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CurrentNotesDetail &&
            (identical(other.book, book) || other.book == book) &&
            (identical(other.numberOfNotes, numberOfNotes) ||
                other.numberOfNotes == numberOfNotes));
  }

  @override
  int get hashCode => Object.hash(runtimeType, book, numberOfNotes);

  @override
  String toString() {
    return 'CurrentNotesDetail(book: $book, numberOfNotes: $numberOfNotes)';
  }
}

/// @nodoc
abstract mixin class _$CurrentNotesDetailCopyWith<$Res>
    implements $CurrentNotesDetailCopyWith<$Res> {
  factory _$CurrentNotesDetailCopyWith(
          _CurrentNotesDetail value, $Res Function(_CurrentNotesDetail) _then) =
      __$CurrentNotesDetailCopyWithImpl;
  @override
  @useResult
  $Res call({Book book, int numberOfNotes});
}

/// @nodoc
class __$CurrentNotesDetailCopyWithImpl<$Res>
    implements _$CurrentNotesDetailCopyWith<$Res> {
  __$CurrentNotesDetailCopyWithImpl(this._self, this._then);

  final _CurrentNotesDetail _self;
  final $Res Function(_CurrentNotesDetail) _then;

  /// Create a copy of CurrentNotesDetail
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? book = null,
    Object? numberOfNotes = null,
  }) {
    return _then(_CurrentNotesDetail(
      book: null == book
          ? _self.book
          : book // ignore: cast_nullable_to_non_nullable
              as Book,
      numberOfNotes: null == numberOfNotes
          ? _self.numberOfNotes
          : numberOfNotes // ignore: cast_nullable_to_non_nullable
              as int,
    ));
  }
}

// dart format on
