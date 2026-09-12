// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'current_reading_state.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$CurrentReadingState {
  bool get isReading;
  Book? get book;
  String? get cfi;
  double? get percentage;
  String? get chapterTitle;
  String? get chapterHref;
  int? get chapterCurrentPage;
  int? get chapterTotalPages;

  /// Create a copy of CurrentReadingState
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $CurrentReadingStateCopyWith<CurrentReadingState> get copyWith =>
      _$CurrentReadingStateCopyWithImpl<CurrentReadingState>(
          this as CurrentReadingState, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is CurrentReadingState &&
            (identical(other.isReading, isReading) ||
                other.isReading == isReading) &&
            (identical(other.book, book) || other.book == book) &&
            (identical(other.cfi, cfi) || other.cfi == cfi) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.chapterTitle, chapterTitle) ||
                other.chapterTitle == chapterTitle) &&
            (identical(other.chapterHref, chapterHref) ||
                other.chapterHref == chapterHref) &&
            (identical(other.chapterCurrentPage, chapterCurrentPage) ||
                other.chapterCurrentPage == chapterCurrentPage) &&
            (identical(other.chapterTotalPages, chapterTotalPages) ||
                other.chapterTotalPages == chapterTotalPages));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isReading, book, cfi, percentage,
      chapterTitle, chapterHref, chapterCurrentPage, chapterTotalPages);

  @override
  String toString() {
    return 'CurrentReadingState(isReading: $isReading, book: $book, cfi: $cfi, percentage: $percentage, chapterTitle: $chapterTitle, chapterHref: $chapterHref, chapterCurrentPage: $chapterCurrentPage, chapterTotalPages: $chapterTotalPages)';
  }
}

/// @nodoc
abstract mixin class $CurrentReadingStateCopyWith<$Res> {
  factory $CurrentReadingStateCopyWith(
          CurrentReadingState value, $Res Function(CurrentReadingState) _then) =
      _$CurrentReadingStateCopyWithImpl;
  @useResult
  $Res call(
      {bool isReading,
      Book? book,
      String? cfi,
      double? percentage,
      String? chapterTitle,
      String? chapterHref,
      int? chapterCurrentPage,
      int? chapterTotalPages});
}

/// @nodoc
class _$CurrentReadingStateCopyWithImpl<$Res>
    implements $CurrentReadingStateCopyWith<$Res> {
  _$CurrentReadingStateCopyWithImpl(this._self, this._then);

  final CurrentReadingState _self;
  final $Res Function(CurrentReadingState) _then;

  /// Create a copy of CurrentReadingState
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? isReading = null,
    Object? book = freezed,
    Object? cfi = freezed,
    Object? percentage = freezed,
    Object? chapterTitle = freezed,
    Object? chapterHref = freezed,
    Object? chapterCurrentPage = freezed,
    Object? chapterTotalPages = freezed,
  }) {
    return _then(_self.copyWith(
      isReading: null == isReading
          ? _self.isReading
          : isReading // ignore: cast_nullable_to_non_nullable
              as bool,
      book: freezed == book
          ? _self.book
          : book // ignore: cast_nullable_to_non_nullable
              as Book?,
      cfi: freezed == cfi
          ? _self.cfi
          : cfi // ignore: cast_nullable_to_non_nullable
              as String?,
      percentage: freezed == percentage
          ? _self.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double?,
      chapterTitle: freezed == chapterTitle
          ? _self.chapterTitle
          : chapterTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      chapterHref: freezed == chapterHref
          ? _self.chapterHref
          : chapterHref // ignore: cast_nullable_to_non_nullable
              as String?,
      chapterCurrentPage: freezed == chapterCurrentPage
          ? _self.chapterCurrentPage
          : chapterCurrentPage // ignore: cast_nullable_to_non_nullable
              as int?,
      chapterTotalPages: freezed == chapterTotalPages
          ? _self.chapterTotalPages
          : chapterTotalPages // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc

class _CurrentReadingState implements CurrentReadingState {
  const _CurrentReadingState(
      {this.isReading = false,
      this.book,
      this.cfi,
      this.percentage,
      this.chapterTitle,
      this.chapterHref,
      this.chapterCurrentPage,
      this.chapterTotalPages});

  @override
  @JsonKey()
  final bool isReading;
  @override
  final Book? book;
  @override
  final String? cfi;
  @override
  final double? percentage;
  @override
  final String? chapterTitle;
  @override
  final String? chapterHref;
  @override
  final int? chapterCurrentPage;
  @override
  final int? chapterTotalPages;

  /// Create a copy of CurrentReadingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$CurrentReadingStateCopyWith<_CurrentReadingState> get copyWith =>
      __$CurrentReadingStateCopyWithImpl<_CurrentReadingState>(
          this, _$identity);

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _CurrentReadingState &&
            (identical(other.isReading, isReading) ||
                other.isReading == isReading) &&
            (identical(other.book, book) || other.book == book) &&
            (identical(other.cfi, cfi) || other.cfi == cfi) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.chapterTitle, chapterTitle) ||
                other.chapterTitle == chapterTitle) &&
            (identical(other.chapterHref, chapterHref) ||
                other.chapterHref == chapterHref) &&
            (identical(other.chapterCurrentPage, chapterCurrentPage) ||
                other.chapterCurrentPage == chapterCurrentPage) &&
            (identical(other.chapterTotalPages, chapterTotalPages) ||
                other.chapterTotalPages == chapterTotalPages));
  }

  @override
  int get hashCode => Object.hash(runtimeType, isReading, book, cfi, percentage,
      chapterTitle, chapterHref, chapterCurrentPage, chapterTotalPages);

  @override
  String toString() {
    return 'CurrentReadingState(isReading: $isReading, book: $book, cfi: $cfi, percentage: $percentage, chapterTitle: $chapterTitle, chapterHref: $chapterHref, chapterCurrentPage: $chapterCurrentPage, chapterTotalPages: $chapterTotalPages)';
  }
}

/// @nodoc
abstract mixin class _$CurrentReadingStateCopyWith<$Res>
    implements $CurrentReadingStateCopyWith<$Res> {
  factory _$CurrentReadingStateCopyWith(_CurrentReadingState value,
          $Res Function(_CurrentReadingState) _then) =
      __$CurrentReadingStateCopyWithImpl;
  @override
  @useResult
  $Res call(
      {bool isReading,
      Book? book,
      String? cfi,
      double? percentage,
      String? chapterTitle,
      String? chapterHref,
      int? chapterCurrentPage,
      int? chapterTotalPages});
}

/// @nodoc
class __$CurrentReadingStateCopyWithImpl<$Res>
    implements _$CurrentReadingStateCopyWith<$Res> {
  __$CurrentReadingStateCopyWithImpl(this._self, this._then);

  final _CurrentReadingState _self;
  final $Res Function(_CurrentReadingState) _then;

  /// Create a copy of CurrentReadingState
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? isReading = null,
    Object? book = freezed,
    Object? cfi = freezed,
    Object? percentage = freezed,
    Object? chapterTitle = freezed,
    Object? chapterHref = freezed,
    Object? chapterCurrentPage = freezed,
    Object? chapterTotalPages = freezed,
  }) {
    return _then(_CurrentReadingState(
      isReading: null == isReading
          ? _self.isReading
          : isReading // ignore: cast_nullable_to_non_nullable
              as bool,
      book: freezed == book
          ? _self.book
          : book // ignore: cast_nullable_to_non_nullable
              as Book?,
      cfi: freezed == cfi
          ? _self.cfi
          : cfi // ignore: cast_nullable_to_non_nullable
              as String?,
      percentage: freezed == percentage
          ? _self.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double?,
      chapterTitle: freezed == chapterTitle
          ? _self.chapterTitle
          : chapterTitle // ignore: cast_nullable_to_non_nullable
              as String?,
      chapterHref: freezed == chapterHref
          ? _self.chapterHref
          : chapterHref // ignore: cast_nullable_to_non_nullable
              as String?,
      chapterCurrentPage: freezed == chapterCurrentPage
          ? _self.chapterCurrentPage
          : chapterCurrentPage // ignore: cast_nullable_to_non_nullable
              as int?,
      chapterTotalPages: freezed == chapterTotalPages
          ? _self.chapterTotalPages
          : chapterTotalPages // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
