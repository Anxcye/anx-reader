// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookshelf_lookup_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookshelfLookupInput _$BookshelfLookupInputFromJson(
        Map<String, dynamic> json) =>
    _BookshelfLookupInput(
      query: json['query'] as String?,
      groupId: (json['groupId'] as num?)?.toInt(),
      includeDeleted: json['includeDeleted'] as bool? ?? false,
      limit: (json['limit'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookshelfLookupInputToJson(
        _BookshelfLookupInput instance) =>
    <String, dynamic>{
      'query': instance.query,
      'groupId': instance.groupId,
      'includeDeleted': instance.includeDeleted,
      'limit': instance.limit,
    };
