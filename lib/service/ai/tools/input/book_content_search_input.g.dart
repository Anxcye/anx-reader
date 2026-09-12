// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'book_content_search_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookContentSearchInput _$BookContentSearchInputFromJson(
        Map<String, dynamic> json) =>
    _BookContentSearchInput(
      bookId: (json['bookId'] as num).toInt(),
      keyword: json['keyword'] as String,
      maxResults: (json['maxResults'] as num?)?.toInt(),
      maxSnippets: (json['maxSnippets'] as num?)?.toInt(),
      maxCharacters: (json['maxCharacters'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookContentSearchInputToJson(
        _BookContentSearchInput instance) =>
    <String, dynamic>{
      'bookId': instance.bookId,
      'keyword': instance.keyword,
      'maxResults': instance.maxResults,
      'maxSnippets': instance.maxSnippets,
      'maxCharacters': instance.maxCharacters,
    };
