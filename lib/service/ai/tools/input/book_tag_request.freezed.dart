// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'book_tag_request.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookTagRequest {
  String get bookTitle;
  int get bookId;
  List<String> get tags;

  /// Create a copy of BookTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookTagRequestCopyWith<BookTagRequest> get copyWith =>
      _$BookTagRequestCopyWithImpl<BookTagRequest>(
          this as BookTagRequest, _$identity);

  /// Serializes this BookTagRequest to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookTagRequest &&
            (identical(other.bookTitle, bookTitle) ||
                other.bookTitle == bookTitle) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            const DeepCollectionEquality().equals(other.tags, tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, bookTitle, bookId,
      const DeepCollectionEquality().hash(tags));

  @override
  String toString() {
    return 'BookTagRequest(bookTitle: $bookTitle, bookId: $bookId, tags: $tags)';
  }
}

/// @nodoc
abstract mixin class $BookTagRequestCopyWith<$Res> {
  factory $BookTagRequestCopyWith(
          BookTagRequest value, $Res Function(BookTagRequest) _then) =
      _$BookTagRequestCopyWithImpl;
  @useResult
  $Res call({String bookTitle, int bookId, List<String> tags});
}

/// @nodoc
class _$BookTagRequestCopyWithImpl<$Res>
    implements $BookTagRequestCopyWith<$Res> {
  _$BookTagRequestCopyWithImpl(this._self, this._then);

  final BookTagRequest _self;
  final $Res Function(BookTagRequest) _then;

  /// Create a copy of BookTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? bookTitle = null,
    Object? bookId = null,
    Object? tags = null,
  }) {
    return _then(_self.copyWith(
      bookTitle: null == bookTitle
          ? _self.bookTitle
          : bookTitle // ignore: cast_nullable_to_non_nullable
              as String,
      bookId: null == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _self.tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BookTagRequest extends BookTagRequest {
  const _BookTagRequest(
      {required this.bookTitle,
      required this.bookId,
      final List<String> tags = const <String>[]})
      : _tags = tags,
        super._();
  factory _BookTagRequest.fromJson(Map<String, dynamic> json) =>
      _$BookTagRequestFromJson(json);

  @override
  final String bookTitle;
  @override
  final int bookId;
  final List<String> _tags;
  @override
  @JsonKey()
  List<String> get tags {
    if (_tags is EqualUnmodifiableListView) return _tags;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tags);
  }

  /// Create a copy of BookTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookTagRequestCopyWith<_BookTagRequest> get copyWith =>
      __$BookTagRequestCopyWithImpl<_BookTagRequest>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookTagRequestToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookTagRequest &&
            (identical(other.bookTitle, bookTitle) ||
                other.bookTitle == bookTitle) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            const DeepCollectionEquality().equals(other._tags, _tags));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, bookTitle, bookId,
      const DeepCollectionEquality().hash(_tags));

  @override
  String toString() {
    return 'BookTagRequest(bookTitle: $bookTitle, bookId: $bookId, tags: $tags)';
  }
}

/// @nodoc
abstract mixin class _$BookTagRequestCopyWith<$Res>
    implements $BookTagRequestCopyWith<$Res> {
  factory _$BookTagRequestCopyWith(
          _BookTagRequest value, $Res Function(_BookTagRequest) _then) =
      __$BookTagRequestCopyWithImpl;
  @override
  @useResult
  $Res call({String bookTitle, int bookId, List<String> tags});
}

/// @nodoc
class __$BookTagRequestCopyWithImpl<$Res>
    implements _$BookTagRequestCopyWith<$Res> {
  __$BookTagRequestCopyWithImpl(this._self, this._then);

  final _BookTagRequest _self;
  final $Res Function(_BookTagRequest) _then;

  /// Create a copy of BookTagRequest
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? bookTitle = null,
    Object? bookId = null,
    Object? tags = null,
  }) {
    return _then(_BookTagRequest(
      bookTitle: null == bookTitle
          ? _self.bookTitle
          : bookTitle // ignore: cast_nullable_to_non_nullable
              as String,
      bookId: null == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int,
      tags: null == tags
          ? _self._tags
          : tags // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

// dart format on
