import 'package:anx_reader/enums/sync_direction.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_state_model.freezed.dart';
part 'sync_state_model.g.dart';

@freezed
abstract class SyncStateModel with _$SyncStateModel {
  const factory SyncStateModel({
    required SyncDirection direction,
    required bool isSyncing,
    required int total,
    required int count,
    required String fileName,
  }) = _SyncState;

  factory SyncStateModel.fromJson(Map<String, dynamic> json) =>
      _$SyncStateModelFromJson(json);
}
