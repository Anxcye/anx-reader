// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookshelf_organize_plan.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookshelfOrganizePlan _$BookshelfOrganizePlanFromJson(
        Map<String, dynamic> json) =>
    _BookshelfOrganizePlan(
      groups: (json['groups'] as List<dynamic>?)
              ?.map((e) => BookshelfOrganizePlanGroup.fromJson(
                  e as Map<String, dynamic>))
              .toList() ??
          const <BookshelfOrganizePlanGroup>[],
      ungroupedBooks: (json['ungroupedBooks'] as List<dynamic>?)
              ?.map((e) =>
                  BookshelfOrganizePlanBook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BookshelfOrganizePlanBook>[],
      cleanupGroupIds: (json['cleanupGroupIds'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const <int>[],
      summary: json['summary'] as String?,
    );

Map<String, dynamic> _$BookshelfOrganizePlanToJson(
        _BookshelfOrganizePlan instance) =>
    <String, dynamic>{
      'groups': instance.groups,
      'ungroupedBooks': instance.ungroupedBooks,
      'cleanupGroupIds': instance.cleanupGroupIds,
      'summary': instance.summary,
    };
