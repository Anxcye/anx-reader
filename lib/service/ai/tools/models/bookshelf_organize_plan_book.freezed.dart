// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookshelf_organize_plan_book.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookshelfOrganizePlanBook {
  int get bookId;
  String get title;
  String? get author;
  int? get previousGroupId;

  /// Create a copy of BookshelfOrganizePlanBook
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookshelfOrganizePlanBookCopyWith<BookshelfOrganizePlanBook> get copyWith =>
      _$BookshelfOrganizePlanBookCopyWithImpl<BookshelfOrganizePlanBook>(
          this as BookshelfOrganizePlanBook, _$identity);

  /// Serializes this BookshelfOrganizePlanBook to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookshelfOrganizePlanBook &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.previousGroupId, previousGroupId) ||
                other.previousGroupId == previousGroupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, bookId, title, author, previousGroupId);

  @override
  String toString() {
    return 'BookshelfOrganizePlanBook(bookId: $bookId, title: $title, author: $author, previousGroupId: $previousGroupId)';
  }
}

/// @nodoc
abstract mixin class $BookshelfOrganizePlanBookCopyWith<$Res> {
  factory $BookshelfOrganizePlanBookCopyWith(BookshelfOrganizePlanBook value,
          $Res Function(BookshelfOrganizePlanBook) _then) =
      _$BookshelfOrganizePlanBookCopyWithImpl;
  @useResult
  $Res call({int bookId, String title, String? author, int? previousGroupId});
}

/// @nodoc
class _$BookshelfOrganizePlanBookCopyWithImpl<$Res>
    implements $BookshelfOrganizePlanBookCopyWith<$Res> {
  _$BookshelfOrganizePlanBookCopyWithImpl(this._self, this._then);

  final BookshelfOrganizePlanBook _self;
  final $Res Function(BookshelfOrganizePlanBook) _then;

  /// Create a copy of BookshelfOrganizePlanBook
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookId = null,
    Object? title = null,
    Object? author = freezed,
    Object? previousGroupId = freezed,
  }) {
    return _then(_self.copyWith(
      bookId: null == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: freezed == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      previousGroupId: freezed == previousGroupId
          ? _self.previousGroupId
          : previousGroupId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BookshelfOrganizePlanBook extends BookshelfOrganizePlanBook {
  const _BookshelfOrganizePlanBook(
      {required this.bookId,
      required this.title,
      this.author,
      this.previousGroupId})
      : super._();
  factory _BookshelfOrganizePlanBook.fromJson(Map<String, dynamic> json) =>
      _$BookshelfOrganizePlanBookFromJson(json);

  @override
  final int bookId;
  @override
  final String title;
  @override
  final String? author;
  @override
  final int? previousGroupId;

  /// Create a copy of BookshelfOrganizePlanBook
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookshelfOrganizePlanBookCopyWith<_BookshelfOrganizePlanBook>
      get copyWith =>
          __$BookshelfOrganizePlanBookCopyWithImpl<_BookshelfOrganizePlanBook>(
              this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookshelfOrganizePlanBookToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookshelfOrganizePlanBook &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.title, title) || other.title == title) &&
            (identical(other.author, author) || other.author == author) &&
            (identical(other.previousGroupId, previousGroupId) ||
                other.previousGroupId == previousGroupId));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, bookId, title, author, previousGroupId);

  @override
  String toString() {
    return 'BookshelfOrganizePlanBook(bookId: $bookId, title: $title, author: $author, previousGroupId: $previousGroupId)';
  }
}

/// @nodoc
abstract mixin class _$BookshelfOrganizePlanBookCopyWith<$Res>
    implements $BookshelfOrganizePlanBookCopyWith<$Res> {
  factory _$BookshelfOrganizePlanBookCopyWith(_BookshelfOrganizePlanBook value,
          $Res Function(_BookshelfOrganizePlanBook) _then) =
      __$BookshelfOrganizePlanBookCopyWithImpl;
  @override
  @useResult
  $Res call({int bookId, String title, String? author, int? previousGroupId});
}

/// @nodoc
class __$BookshelfOrganizePlanBookCopyWithImpl<$Res>
    implements _$BookshelfOrganizePlanBookCopyWith<$Res> {
  __$BookshelfOrganizePlanBookCopyWithImpl(this._self, this._then);

  final _BookshelfOrganizePlanBook _self;
  final $Res Function(_BookshelfOrganizePlanBook) _then;

  /// Create a copy of BookshelfOrganizePlanBook
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bookId = null,
    Object? title = null,
    Object? author = freezed,
    Object? previousGroupId = freezed,
  }) {
    return _then(_BookshelfOrganizePlanBook(
      bookId: null == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int,
      title: null == title
          ? _self.title
          : title // ignore: cast_nullable_to_non_nullable
              as String,
      author: freezed == author
          ? _self.author
          : author // ignore: cast_nullable_to_non_nullable
              as String?,
      previousGroupId: freezed == previousGroupId
          ? _self.previousGroupId
          : previousGroupId // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

// dart format on
