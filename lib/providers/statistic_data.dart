import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/enums/chart_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/statistic_data_model.dart';
import 'package:flutter/cupertino.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'statistic_data.g.dart';

@riverpod
class StatisticData extends _$StatisticData {
  Future<void> _updateState({
    ChartMode? mode,
    bool? isSelectingDay,
    DateTime? date,
  }) async {
    state = const AsyncValue.loading();
    try {
      final currentState = state.valueOrNull!;
      final newMode = mode ?? currentState.mode;
      final newIsSelectingDay = isSelectingDay ?? currentState.isSelectingDay;
      final newDate = date ?? currentState.date;

      state = AsyncValue.data(await _fetchData(
        newMode,
        newIsSelectingDay,
        newDate,
      ));
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> setMode(ChartMode mode) => _updateState(mode: mode);
  Future<void> setIsSelectingDay(bool value) => _updateState(isSelectingDay: value);
  Future<void> setDate(DateTime date) => _updateState(date: date);

  Future<StatisticDataModel> _fetchData(
      ChartMode mode,
      bool isSelectingDay,
      DateTime date,
      ) async {
    return StatisticDataModel(
      mode: mode,
      isSelectingDay: isSelectingDay,
      date: date,
      readingTime: await _getReadingTime(mode, date),
      xLabels: _getxLabels(mode, date),
      bookReadingTime: await _getBookReadingTime(isSelectingDay, mode, date),
    );
  }

  Future<List<int>> _getReadingTime(ChartMode mode, DateTime date) {
    final readingTimeMap = {
      ChartMode.week: () => selectReadingTimeOfWeek(date),
      ChartMode.month: () => selectReadingTimeOfMonth(date),
      ChartMode.year: () => selectReadingTimeOfYear(date),
    };
    return readingTimeMap[mode]!();
  }

  List<String> _getxLabels(ChartMode mode, DateTime date) {
    BuildContext context = navigatorKey.currentContext!;
    final labelGenerators = {
      ChartMode.week: () => [
        L10n.of(context).statistic_monday,
        L10n.of(context).statistic_tuesday,
        L10n.of(context).statistic_wednesday,
        L10n.of(context).statistic_thursday,
        L10n.of(context).statistic_friday,
        L10n.of(context).statistic_saturday,
        L10n.of(context).statistic_sunday,
      ],
      ChartMode.month: () {
        final daysInMonth = DateTime(date.year, date.month + 1, 0).day;
        return List.generate(daysInMonth,
                (i) => (i + 1) % 5 == 0 || i == 0 ? (i + 1).toString() : '');
      },
      ChartMode.year: () => List.generate(12, (i) => (i + 1).toString()),
    };
    return labelGenerators[mode]!();
  }

  Future<List<Map<Book, int>>> _getBookReadingTime(
      bool isSelectingDay,
      ChartMode mode,
      DateTime date,
      ) {
    if (isSelectingDay) {
      return selectBookReadingTimeOfDay(date);
    }
    else{
      final bookReadingTimeMap = {
        ChartMode.week: () => selectBookReadingTimeOfWeek(date),
        ChartMode.month: () => selectBookReadingTimeOfMonth(date),
        ChartMode.year: () => selectBookReadingTimeOfYear(date),
      };
      return bookReadingTimeMap[mode]!();
    }
  }

  @override
  FutureOr<StatisticDataModel> build() async {
    const initialMode = ChartMode.week;
    final initialDate = DateTime.now();

    return _fetchData(
      initialMode,
      false,
      initialDate,
    );
  }


}
