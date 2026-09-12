// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'chapter_content_by_href_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ChapterContentByHrefInput _$ChapterContentByHrefInputFromJson(
        Map<String, dynamic> json) =>
    _ChapterContentByHrefInput(
      href: json['href'] as String,
      maxCharacters: (json['maxCharacters'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ChapterContentByHrefInputToJson(
        _ChapterContentByHrefInput instance) =>
    <String, dynamic>{
      'href': instance.href,
      'maxCharacters': instance.maxCharacters,
    };
