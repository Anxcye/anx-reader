import 'package:anx_reader/dao/reading_time.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'total_reading_time.g.dart';

@riverpod
class TotalReadingTime extends _$TotalReadingTime {
  @override
  Future<int> build() async {
    return _getTotalReadingTime();
  }

  Future<int> _getTotalReadingTime() async {
    return await selectTotalReadingTime();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _getTotalReadingTime());
  }
}
