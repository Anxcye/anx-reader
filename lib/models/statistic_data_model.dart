import 'package:anx_reader/enums/chart_mode.dart';
import 'package:anx_reader/models/book.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'statistic_data_model.freezed.dart';

@freezed
class StatisticDataModel with _$StatisticDataModel {
  const factory StatisticDataModel({
    required ChartMode mode,
    required bool isSelectingDay,
    required DateTime date,
    required List<int> readingTime,
    required List<String> xLabels,
    required List<Map<Book, int>> bookReadingTime
  }) = _StatisticDataModel;
}