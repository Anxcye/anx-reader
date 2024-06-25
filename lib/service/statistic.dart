import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/dao/reading_time.dart';


class StatisticService {
  static StatisticService? _instance;

  StatisticService._() {
    Future.microtask(() async {
      readingTimes = await selectAllReadingTime();
    });
  }

  factory StatisticService() {
    _instance ??= StatisticService._();
    return _instance!;
  }

  List<ReadingTime> readingTimes = [];

  int get totalReadingTime {
    return readingTimes.fold<int>(0, (previousValue, element) => previousValue + element.readingTime);
  }

}