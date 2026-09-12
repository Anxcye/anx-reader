// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookshelf_organize_group_spec.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookshelfOrganizeGroupSpec _$BookshelfOrganizeGroupSpecFromJson(
        Map<String, dynamic> json) =>
    _BookshelfOrganizeGroupSpec(
      groupId: (json['groupId'] as num).toInt(),
      bookIds: (json['bookIds'] as List<dynamic>)
          .map((e) => (e as num).toInt())
          .toList(),
      name: json['name'] as String?,
      createNew: json['createNew'] as bool?,
      renameTo: json['renameTo'] as String?,
    );

Map<String, dynamic> _$BookshelfOrganizeGroupSpecToJson(
        _BookshelfOrganizeGroupSpec instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'bookIds': instance.bookIds,
      'name': instance.name,
      'createNew': instance.createNew,
      'renameTo': instance.renameTo,
    };
