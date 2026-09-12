// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bgimg.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BgimgModel _$BgimgModelFromJson(Map<String, dynamic> json) => _BgimgModel(
      type: $enumDecode(_$BgimgTypeEnumMap, json['type']),
      path: json['path'] as String,
      nightPath: json['nightPath'] as String?,
      alignment: $enumDecode(_$BgimgAlignmentEnumMap, json['alignment']),
      selectedMode:
          $enumDecodeNullable(_$BgimgThemeModeEnumMap, json['selectedMode']),
      blur: (json['blur'] as num?)?.toDouble() ?? 0.0,
      opacity: (json['opacity'] as num?)?.toDouble() ?? 1.0,
    );

Map<String, dynamic> _$BgimgModelToJson(_BgimgModel instance) =>
    <String, dynamic>{
      'type': _$BgimgTypeEnumMap[instance.type]!,
      'path': instance.path,
      'nightPath': instance.nightPath,
      'alignment': _$BgimgAlignmentEnumMap[instance.alignment]!,
      'selectedMode': _$BgimgThemeModeEnumMap[instance.selectedMode],
      'blur': instance.blur,
      'opacity': instance.opacity,
    };

const _$BgimgTypeEnumMap = {
  BgimgType.none: 'none',
  BgimgType.assets: 'assets',
  BgimgType.localFile: 'localFile',
};

const _$BgimgAlignmentEnumMap = {
  BgimgAlignment.center: 'center',
  BgimgAlignment.top: 'top',
  BgimgAlignment.bottom: 'bottom',
  BgimgAlignment.left: 'left',
  BgimgAlignment.right: 'right',
};

const _$BgimgThemeModeEnumMap = {
  BgimgThemeMode.day: 'day',
  BgimgThemeMode.night: 'night',
};
