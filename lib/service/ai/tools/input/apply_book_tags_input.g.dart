// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'apply_book_tags_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ApplyBookTagsInput _$ApplyBookTagsInputFromJson(Map<String, dynamic> json) =>
    _ApplyBookTagsInput(
      books: (json['books'] as List<dynamic>?)
              ?.map((e) => BookTagRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <BookTagRequest>[],
      createTags: (json['createTags'] as List<dynamic>?)
              ?.map((e) => CreateTagRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <CreateTagRequest>[],
      updateTags: (json['updateTags'] as List<dynamic>?)
              ?.map((e) => UpdateTagRequest.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const <UpdateTagRequest>[],
    );

Map<String, dynamic> _$ApplyBookTagsInputToJson(_ApplyBookTagsInput instance) =>
    <String, dynamic>{
      'books': instance.books,
      'createTags': instance.createTags,
      'updateTags': instance.updateTags,
    };
