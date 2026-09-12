// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookshelf_organize_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookshelfOrganizeInput _$BookshelfOrganizeInputFromJson(
        Map<String, dynamic> json) =>
    _BookshelfOrganizeInput(
      groups: (json['groups'] as List<dynamic>)
          .map((e) =>
              BookshelfOrganizeGroupSpec.fromJson(e as Map<String, dynamic>))
          .toList(),
      ungroupedBookIds: (json['ungroupedBookIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      cleanupGroupIds: (json['cleanupGroupIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      summary: json['summary'] as String?,
    );

Map<String, dynamic> _$BookshelfOrganizeInputToJson(
        _BookshelfOrganizeInput instance) =>
    <String, dynamic>{
      'groups': instance.groups,
      'ungroupedBookIds': instance.ungroupedBookIds,
      'cleanupGroupIds': instance.cleanupGroupIds,
      'summary': instance.summary,
    };
