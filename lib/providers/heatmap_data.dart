import 'package:anx_reader/dao/reading_time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'heatmap_data.g.dart';

@riverpod
class HeatmapData extends _$HeatmapData {
  @override
  FutureOr<Map<DateTime, int>> build() async {
    return await selectAllReadingTimeGroupByDay();
  }
}
