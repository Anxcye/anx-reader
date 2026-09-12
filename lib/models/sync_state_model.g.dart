// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'sync_state_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SyncState _$SyncStateFromJson(Map<String, dynamic> json) => _SyncState(
      direction: $enumDecode(_$SyncDirectionEnumMap, json['direction']),
      isSyncing: json['isSyncing'] as bool,
      total: (json['total'] as num).toInt(),
      count: (json['count'] as num).toInt(),
      fileName: json['fileName'] as String,
    );

Map<String, dynamic> _$SyncStateToJson(_SyncState instance) =>
    <String, dynamic>{
      'direction': _$SyncDirectionEnumMap[instance.direction]!,
      'isSyncing': instance.isSyncing,
      'total': instance.total,
      'count': instance.count,
      'fileName': instance.fileName,
    };

const _$SyncDirectionEnumMap = {
  SyncDirection.upload: 'upload',
  SyncDirection.download: 'download',
  SyncDirection.both: 'both',
};
