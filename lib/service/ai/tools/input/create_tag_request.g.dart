// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'create_tag_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CreateTagRequest _$CreateTagRequestFromJson(Map<String, dynamic> json) =>
    _CreateTagRequest(
      name: json['name'] as String,
      rgb: (json['rgb'] as num?)?.toInt(),
    );

Map<String, dynamic> _$CreateTagRequestToJson(_CreateTagRequest instance) =>
    <String, dynamic>{
      'name': instance.name,
      'rgb': instance.rgb,
    };
