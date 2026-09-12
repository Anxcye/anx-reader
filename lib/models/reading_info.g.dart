// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReadingInfoSectionModel _$ReadingInfoSectionModelFromJson(
        Map<String, dynamic> json) =>
    _ReadingInfoSectionModel(
      left: $enumDecodeNullable(_$ReadingInfoEnumEnumMap, json['left']) ??
          ReadingInfoEnum.none,
      center: $enumDecodeNullable(_$ReadingInfoEnumEnumMap, json['center']) ??
          ReadingInfoEnum.none,
      right: $enumDecodeNullable(_$ReadingInfoEnumEnumMap, json['right']) ??
          ReadingInfoEnum.none,
      verticalMargin: (json['verticalMargin'] as num?)?.toDouble() ?? 0,
      leftMargin: (json['leftMargin'] as num?)?.toDouble() ?? 20,
      rightMargin: (json['rightMargin'] as num?)?.toDouble() ?? 20,
      fontSize: (json['fontSize'] as num?)?.toDouble() ?? 10,
    );

Map<String, dynamic> _$ReadingInfoSectionModelToJson(
        _ReadingInfoSectionModel instance) =>
    <String, dynamic>{
      'left': _$ReadingInfoEnumEnumMap[instance.left]!,
      'center': _$ReadingInfoEnumEnumMap[instance.center]!,
      'right': _$ReadingInfoEnumEnumMap[instance.right]!,
      'verticalMargin': instance.verticalMargin,
      'leftMargin': instance.leftMargin,
      'rightMargin': instance.rightMargin,
      'fontSize': instance.fontSize,
    };

const _$ReadingInfoEnumEnumMap = {
  ReadingInfoEnum.none: 'none',
  ReadingInfoEnum.chapterTitle: 'chapterTitle',
  ReadingInfoEnum.chapterProgress: 'chapterProgress',
  ReadingInfoEnum.bookProgress: 'bookProgress',
  ReadingInfoEnum.battery: 'battery',
  ReadingInfoEnum.time: 'time',
  ReadingInfoEnum.batteryAndTime: 'batteryAndTime',
};

_ReadingInfoModel _$ReadingInfoModelFromJson(Map<String, dynamic> json) =>
    _ReadingInfoModel(
      header: json['header'] == null
          ? const ReadingInfoSectionModel(left: ReadingInfoEnum.chapterTitle)
          : ReadingInfoSectionModel.fromJson(
              json['header'] as Map<String, dynamic>),
      footer: json['footer'] == null
          ? const ReadingInfoSectionModel(
              left: ReadingInfoEnum.batteryAndTime,
              center: ReadingInfoEnum.chapterProgress,
              right: ReadingInfoEnum.bookProgress)
          : ReadingInfoSectionModel.fromJson(
              json['footer'] as Map<String, dynamic>),
    );

Map<String, dynamic> _$ReadingInfoModelToJson(_ReadingInfoModel instance) =>
    <String, dynamic>{
      'header': instance.header,
      'footer': instance.footer,
    };
