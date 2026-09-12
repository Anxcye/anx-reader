// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tb_group.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_TbGroup _$TbGroupFromJson(Map<String, dynamic> json) => _TbGroup(
      id: (json['id'] as num).toInt(),
      name: json['name'] as String,
      parentId: (json['parentId'] as num?)?.toInt(),
      isDeleted: (json['isDeleted'] as num?)?.toInt() ?? 0,
      createTime: json['createTime'] as String?,
      updateTime: json['updateTime'] as String?,
    );

Map<String, dynamic> _$TbGroupToJson(_TbGroup instance) => <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'parentId': instance.parentId,
      'isDeleted': instance.isDeleted,
      'createTime': instance.createTime,
      'updateTime': instance.updateTime,
    };
