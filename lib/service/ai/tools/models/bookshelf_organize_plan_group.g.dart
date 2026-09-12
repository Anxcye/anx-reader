// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookshelf_organize_plan_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookshelfOrganizePlanGroup _$BookshelfOrganizePlanGroupFromJson(
        Map<String, dynamic> json) =>
    _BookshelfOrganizePlanGroup(
      groupId: (json['groupId'] as num).toInt(),
      books: (json['books'] as List<dynamic>?)
              ?.map((e) =>
                  BookshelfOrganizePlanBook.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BookshelfOrganizePlanBook>[],
      createNew: json['createNew'] as bool,
      currentName: json['currentName'] as String?,
      proposedName: json['proposedName'] as String?,
    );

Map<String, dynamic> _$BookshelfOrganizePlanGroupToJson(
        _BookshelfOrganizePlanGroup instance) =>
    <String, dynamic>{
      'groupId': instance.groupId,
      'books': instance.books,
      'createNew': instance.createNew,
      'currentName': instance.currentName,
      'proposedName': instance.proposedName,
    };
