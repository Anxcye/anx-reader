// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_tag_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookTagRequest _$BookTagRequestFromJson(Map<String, dynamic> json) =>
    _BookTagRequest(
      bookTitle: json['bookTitle'] as String,
      bookId: (json['bookId'] as num).toInt(),
      tags:
          (json['tags'] as List<dynamic>?)?.map((e) => e as String).toList() ??
              const <String>[],
    );

Map<String, dynamic> _$BookTagRequestToJson(_BookTagRequest instance) =>
    <String, dynamic>{
      'bookTitle': instance.bookTitle,
      'bookId': instance.bookId,
      'tags': instance.tags,
    };
