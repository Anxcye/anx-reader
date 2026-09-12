// dart format width=80
// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'bookmark.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

// dart format off
T _$identity<T>(T value) => value;

/// @nodoc
mixin _$BookmarkModel {
  int? get id;
  int get bookId;
  String get content;
  String get cfi;
  String get chapter;
  double get percentage;
  DateTime? get createTime;
  DateTime get updateTime;

  /// Create a copy of BookmarkModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  $BookmarkModelCopyWith<BookmarkModel> get copyWith =>
      _$BookmarkModelCopyWithImpl<BookmarkModel>(
          this as BookmarkModel, _$identity);

  /// Serializes this BookmarkModel to a JSON map.
  Map<String, dynamic> toJson();

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is BookmarkModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.cfi, cfi) || other.cfi == cfi) &&
            (identical(other.chapter, chapter) || other.chapter == chapter) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, bookId, content, cfi,
      chapter, percentage, createTime, updateTime);

  @override
  String toString() {
    return 'BookmarkModel(id: $id, bookId: $bookId, content: $content, cfi: $cfi, chapter: $chapter, percentage: $percentage, createTime: $createTime, updateTime: $updateTime)';
  }
}

/// @nodoc
abstract mixin class $BookmarkModelCopyWith<$Res> {
  factory $BookmarkModelCopyWith(
          BookmarkModel value, $Res Function(BookmarkModel) _then) =
      _$BookmarkModelCopyWithImpl;
  @useResult
  $Res call(
      {int? id,
      int bookId,
      String content,
      String cfi,
      String chapter,
      double percentage,
      DateTime? createTime,
      DateTime updateTime});
}

/// @nodoc
class _$BookmarkModelCopyWithImpl<$Res>
    implements $BookmarkModelCopyWith<$Res> {
  _$BookmarkModelCopyWithImpl(this._self, this._then);

  final BookmarkModel _self;
  final $Res Function(BookmarkModel) _then;

  /// Create a copy of BookmarkModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = freezed,
    Object? bookId = null,
    Object? content = null,
    Object? cfi = null,
    Object? chapter = null,
    Object? percentage = null,
    Object? createTime = freezed,
    Object? updateTime = null,
  }) {
    return _then(_self.copyWith(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      bookId: null == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      cfi: null == cfi
          ? _self.cfi
          : cfi // ignore: cast_nullable_to_non_nullable
              as String,
      chapter: null == chapter
          ? _self.chapter
          : chapter // ignore: cast_nullable_to_non_nullable
              as String,
      percentage: null == percentage
          ? _self.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      createTime: freezed == createTime
          ? _self.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updateTime: null == updateTime
          ? _self.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _BookmarkModel implements BookmarkModel {
  const _BookmarkModel(
      {this.id,
      required this.bookId,
      required this.content,
      required this.cfi,
      required this.chapter,
      required this.percentage,
      this.createTime,
      required this.updateTime});
  factory _BookmarkModel.fromJson(Map<String, dynamic> json) =>
      _$BookmarkModelFromJson(json);

  @override
  final int? id;
  @override
  final int bookId;
  @override
  final String content;
  @override
  final String cfi;
  @override
  final String chapter;
  @override
  final double percentage;
  @override
  final DateTime? createTime;
  @override
  final DateTime updateTime;

  /// Create a copy of BookmarkModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  @pragma('vm:prefer-inline')
  _$BookmarkModelCopyWith<_BookmarkModel> get copyWith =>
      __$BookmarkModelCopyWithImpl<_BookmarkModel>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$BookmarkModelToJson(
      this,
    );
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _BookmarkModel &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.bookId, bookId) || other.bookId == bookId) &&
            (identical(other.content, content) || other.content == content) &&
            (identical(other.cfi, cfi) || other.cfi == cfi) &&
            (identical(other.chapter, chapter) || other.chapter == chapter) &&
            (identical(other.percentage, percentage) ||
                other.percentage == percentage) &&
            (identical(other.createTime, createTime) ||
                other.createTime == createTime) &&
            (identical(other.updateTime, updateTime) ||
                other.updateTime == updateTime));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, id, bookId, content, cfi,
      chapter, percentage, createTime, updateTime);

  @override
  String toString() {
    return 'BookmarkModel(id: $id, bookId: $bookId, content: $content, cfi: $cfi, chapter: $chapter, percentage: $percentage, createTime: $createTime, updateTime: $updateTime)';
  }
}

/// @nodoc
abstract mixin class _$BookmarkModelCopyWith<$Res>
    implements $BookmarkModelCopyWith<$Res> {
  factory _$BookmarkModelCopyWith(
          _BookmarkModel value, $Res Function(_BookmarkModel) _then) =
      __$BookmarkModelCopyWithImpl;
  @override
  @useResult
  $Res call(
      {int? id,
      int bookId,
      String content,
      String cfi,
      String chapter,
      double percentage,
      DateTime? createTime,
      DateTime updateTime});
}

/// @nodoc
class __$BookmarkModelCopyWithImpl<$Res>
    implements _$BookmarkModelCopyWith<$Res> {
  __$BookmarkModelCopyWithImpl(this._self, this._then);

  final _BookmarkModel _self;
  final $Res Function(_BookmarkModel) _then;

  /// Create a copy of BookmarkModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $Res call({
    Object? id = freezed,
    Object? bookId = null,
    Object? content = null,
    Object? cfi = null,
    Object? chapter = null,
    Object? percentage = null,
    Object? createTime = freezed,
    Object? updateTime = null,
  }) {
    return _then(_BookmarkModel(
      id: freezed == id
          ? _self.id
          : id // ignore: cast_nullable_to_non_nullable
              as int?,
      bookId: null == bookId
          ? _self.bookId
          : bookId // ignore: cast_nullable_to_non_nullable
              as int,
      content: null == content
          ? _self.content
          : content // ignore: cast_nullable_to_non_nullable
              as String,
      cfi: null == cfi
          ? _self.cfi
          : cfi // ignore: cast_nullable_to_non_nullable
              as String,
      chapter: null == chapter
          ? _self.chapter
          : chapter // ignore: cast_nullable_to_non_nullable
              as String,
      percentage: null == percentage
          ? _self.percentage
          : percentage // ignore: cast_nullable_to_non_nullable
              as double,
      createTime: freezed == createTime
          ? _self.createTime
          : createTime // ignore: cast_nullable_to_non_nullable
              as DateTime?,
      updateTime: null == updateTime
          ? _self.updateTime
          : updateTime // ignore: cast_nullable_to_non_nullable
              as DateTime,
    ));
  }
}

// dart format on
