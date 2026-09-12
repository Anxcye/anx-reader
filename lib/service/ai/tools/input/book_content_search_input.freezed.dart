// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_content_search_input.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookContentSearchInput {
  int get bookId;
  String get keyword;
  int? get maxResults;
  int? get maxSnippets;
  int? get maxCharacters;

  /// Create a copy of BookContentSearchInput
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookContentSearchInputCopyWith<BookContentSearchInput> get copyWith =>
      _$BookContentSearchInputCopyWithImpl<BookContentSearchInput>(
          this as BookContentSearchInput, _$identity);

  /// Serializes this BookContentSearchInput to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookContentSearchInput &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.keyword, keyword) || other.keyword == keyword) &&
            (identical(other.maxResults, maxResults) ||
                other.maxResults == maxResults) &&
            (identical(other.maxSnippets, maxSnippets) ||
                other.maxSnippets == maxSnippets) &&
            (identical(other.maxCharacters, maxCharacters) ||
                other.maxCharacters == maxCharacters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, bookId, keyword, maxResults, maxSnippets, maxCharacters);

  @override
  String toString() {
    return 'BookContentSearchInput(bookId: $bookId, keyword: $keyword, maxResults: $maxResults, maxSnippets: $maxSnippets, maxCharacters: $maxCharacters)';
  }
}

/// @nodoc
abstract mixin class $BookContentSearchInputCopyWith<$Res> {
  factory $BookContentSearchInputCopyWith(BookContentSearchInput value,
          $Res Function(BookContentSearchInput) _then) =
      _$BookContentSearchInputCopyWithImpl;
  @useResult
  $Res call(
      {int bookId,
      String keyword,
      int? maxResults,
      int? maxSnippets,
      int? maxCharacters});
}

/// @nodoc
class _$BookContentSearchInputCopyWithImpl<$Res>
    implements $BookContentSearchInputCopyWith<$Res> {
  _$BookContentSearchInputCopyWithImpl(this._self, this._then);

  final BookContentSearchInput _self;
  final $Res Function(BookContentSearchInput) _then;

  /// Create a copy of BookContentSearchInput
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookId = null,
    Object? keyword = null,
    Object? maxResults = freezed,
    Object? maxSnippets = freezed,
    Object? maxCharacters = freezed,
  }) {
    return _then(_self.copyWith(
      bookId: null == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int,
      keyword: null == keyword
          ? _self.keyword
          : keyword // ignore: cast_nullable_to_non_nullable
              as String,
      maxResults: freezed == maxResults
          ? _self.maxResults
          : maxResults // ignore: cast_nullable_to_non_nullable
              as int?,
      maxSnippets: freezed == maxSnippets
          ? _self.maxSnippets
          : maxSnippets // ignore: cast_nullable_to_non_nullable
              as int?,
      maxCharacters: freezed == maxCharacters
          ? _self.maxCharacters
          : maxCharacters // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BookContentSearchInput extends BookContentSearchInput {
  const _BookContentSearchInput(
      {required this.bookId,
      required this.keyword,
      this.maxResults,
      this.maxSnippets,
      this.maxCharacters})
      : super._();
  factory _BookContentSearchInput.fromJson(Map<String, dynamic> json) =>
      _$BookContentSearchInputFromJson(json);

  @override
  final int bookId;
  @override
  final String keyword;
  @override
  final int? maxResults;
  @override
  final int? maxSnippets;
  @override
  final int? maxCharacters;

  /// Create a copy of BookContentSearchInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookContentSearchInputCopyWith<_BookContentSearchInput> get copyWith =>
      __$BookContentSearchInputCopyWithImpl<_BookContentSearchInput>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookContentSearchInputToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookContentSearchInput &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.keyword, keyword) || other.keyword == keyword) &&
            (identical(other.maxResults, maxResults) ||
                other.maxResults == maxResults) &&
            (identical(other.maxSnippets, maxSnippets) ||
                other.maxSnippets == maxSnippets) &&
            (identical(other.maxCharacters, maxCharacters) ||
                other.maxCharacters == maxCharacters));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType, bookId, keyword, maxResults, maxSnippets, maxCharacters);

  @override
  String toString() {
    return 'BookContentSearchInput(bookId: $bookId, keyword: $keyword, maxResults: $maxResults, maxSnippets: $maxSnippets, maxCharacters: $maxCharacters)';
  }
}

/// @nodoc
abstract mixin class _$BookContentSearchInputCopyWith<$Res>
    implements $BookContentSearchInputCopyWith<$Res> {
  factory _$BookContentSearchInputCopyWith(_BookContentSearchInput value,
          $Res Function(_BookContentSearchInput) _then) =
      __$BookContentSearchInputCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int bookId,
      String keyword,
      int? maxResults,
      int? maxSnippets,
      int? maxCharacters});
}

/// @nodoc
class __$BookContentSearchInputCopyWithImpl<$Res>
    implements _$BookContentSearchInputCopyWith<$Res> {
  __$BookContentSearchInputCopyWithImpl(this._self, this._then);

  final _BookContentSearchInput _self;
  final $Res Function(_BookContentSearchInput) _then;

  /// Create a copy of BookContentSearchInput
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bookId = null,
    Object? keyword = null,
    Object? maxResults = freezed,
    Object? maxSnippets = freezed,
    Object? maxCharacters = freezed,
  }) {
    return _then(_BookContentSearchInput(
      bookId: null == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int,
      keyword: null == keyword
          ? _self.keyword
          : keyword // ignore: cast_nullable_to_non_nullable
              as String,
      maxResults: freezed == maxResults
          ? _self.maxResults
          : maxResults // ignore: cast_nullable_to_non_nullable
              as int?,
      maxSnippets: freezed == maxSnippets
          ? _self.maxSnippets
          : maxSnippets // ignore: cast_nullable_to_non_nullable
              as int?,
      maxCharacters: freezed == maxCharacters
          ? _self.maxCharacters
          : maxCharacters // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
