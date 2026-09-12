// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'user_prompt.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_UserPrompt _$UserPromptFromJson(Map<String, dynamic> json) => _UserPrompt(
      id: json['id'] as String,
      name: json['name'] as String,
      content: json['content'] as String,
      enabled: json['enabled'] as bool? ?? true,
      order: (json['order'] as num).toInt(),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );

Map<String, dynamic> _$UserPromptToJson(_UserPrompt instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'content': instance.content,
      'enabled': instance.enabled,
      'order': instance.order,
      'createdAt': instance.createdAt.toIso8601String(),
      'updatedAt': instance.updatedAt.toIso8601String(),
    };
