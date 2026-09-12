// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'update_tag_request.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UpdateTagRequest _$UpdateTagRequestFromJson(Map<String, dynamic> json) =>
    _UpdateTagRequest(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String?,
      rgb: (json['rgb'] as num?)?.toInt(),
    );

Map<String, dynamic> _$UpdateTagRequestToJson(_UpdateTagRequest instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'rgb': instance.rgb,
    };
