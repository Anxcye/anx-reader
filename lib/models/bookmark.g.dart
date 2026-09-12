// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookmark.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookmarkModel _$BookmarkModelFromJson(Map<String, dynamic> json) =>
    _BookmarkModel(
      id: (json['id'] as num?)?.toInt(),
      bookId: (json['bookId'] as num).toInt(),
      content: json['content'] as String,
      cfi: json['cfi'] as String,
      chapter: json['chapter'] as String,
      percentage: (json['percentage'] as num).toDouble(),
      createTime: json['createTime'] == null
          ? null
          : DateTime.parse(json['createTime'] as String),
      updateTime: DateTime.parse(json['updateTime'] as String),
    );

Map<String, dynamic> _$BookmarkModelToJson(_BookmarkModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'bookId': instance.bookId,
      'content': instance.content,
      'cfi': instance.cfi,
      'chapter': instance.chapter,
      'percentage': instance.percentage,
      'createTime': instance.createTime?.toIso8601String(),
      'updateTime': instance.updateTime.toIso8601String(),
    };
