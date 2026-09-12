// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'window_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WindowInfo _$WindowInfoFromJson(Map<String, dynamic> json) => _WindowInfo(
      x: (json['x'] as num).toDouble(),
      y: (json['y'] as num).toDouble(),
      width: (json['width'] as num).toDouble(),
      height: (json['height'] as num).toDouble(),
      isMaximized: json['isMaximized'] as bool? ?? false,
    );

Map<String, dynamic> _$WindowInfoToJson(_WindowInfo instance) =>
    <String, dynamic>{
      'x': instance.x,
      'y': instance.y,
      'width': instance.width,
      'height': instance.height,
      'isMaximized': instance.isMaximized,
    };
