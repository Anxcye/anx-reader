// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bookshelf_organize_plan_book.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BookshelfOrganizePlanBook _$BookshelfOrganizePlanBookFromJson(
        Map<String, dynamic> json) =>
    _BookshelfOrganizePlanBook(
      bookId: (json['bookId'] as num).toInt(),
      title: json['title'] as String,
      author: json['author'] as String?,
      previousGroupId: (json['previousGroupId'] as num?)?.toInt(),
    );

Map<String, dynamic> _$BookshelfOrganizePlanBookToJson(
        _BookshelfOrganizePlanBook instance) =>
    <String, dynamic>{
      'bookId': instance.bookId,
      'title': instance.title,
      'author': instance.author,
      'previousGroupId': instance.previousGroupId,
    };
