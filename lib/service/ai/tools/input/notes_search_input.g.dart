// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'notes_search_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_NotesSearchInput _$NotesSearchInputFromJson(Map<String, dynamic> json) =>
    _NotesSearchInput(
      keyword: json['keyword'] as String?,
      bookId: (json['bookId'] as num?)?.toInt(),
      from:
          json['from'] == null ? null : DateTime.parse(json['from'] as String),
      to: json['to'] == null ? null : DateTime.parse(json['to'] as String),
      limit: (json['limit'] as num?)?.toInt(),
    );

Map<String, dynamic> _$NotesSearchInputToJson(_NotesSearchInput instance) =>
    <String, dynamic>{
      'keyword': instance.keyword,
      'bookId': instance.bookId,
      'from': instance.from?.toIso8601String(),
      'to': instance.to?.toIso8601String(),
      'limit': instance.limit,
    };
