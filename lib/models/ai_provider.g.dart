// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'ai_provider.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AiApiKey _$AiApiKeyFromJson(Map<String, dynamic> json) => _AiApiKey(
      id: json['id'] as String,
      key: json['key'] as String,
      enabled: json['enabled'] as bool? ?? true,
      label: json['label'] as String?,
      createdAt: json['createdAt'] == null
          ? null
          : DateTime.parse(json['createdAt'] as String),
    );

Map<String, dynamic> _$AiApiKeyToJson(_AiApiKey instance) => <String, dynamic>{
      'id': instance.id,
      'key': instance.key,
      'enabled': instance.enabled,
      'label': instance.label,
      'createdAt': instance.createdAt?.toIso8601String(),
    };
