
import 'package:freezed_annotation/freezed_annotation.dart';
part 'sync_status.freezed.dart';


@freezed
abstract class SyncStatusModel with _$SyncStatusModel {
  const factory SyncStatusModel({
    required List<int> localOnly,
    required List<int> remoteOnly,
    required List<int> both,
    required List<int> nonExistent,
    required List<int> downloading,
    required List<int> uploading,
  }) = _SyncStatusModel;
}
