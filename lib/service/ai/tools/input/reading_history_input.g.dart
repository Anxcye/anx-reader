// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'reading_history_input.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ReadingHistoryInput _$ReadingHistoryInputFromJson(Map<String, dynamic> json) =>
    _ReadingHistoryInput(
      bookId: (json['bookId'] as num?)?.toInt(),
      from:
          json['from'] == null ? null : DateTime.parse(json['from'] as String),
      to: json['to'] == null ? null : DateTime.parse(json['to'] as String),
      limit: (json['limit'] as num?)?.toInt(),
    );

Map<String, dynamic> _$ReadingHistoryInputToJson(
        _ReadingHistoryInput instance) =>
    <String, dynamic>{
      'bookId': instance.bookId,
      'from': instance.from?.toIso8601String(),
      'to': instance.to?.toIso8601String(),
      'limit': instance.limit,
    };
