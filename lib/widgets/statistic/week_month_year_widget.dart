import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/statistic/chard_card.dart';
import 'package:anx_reader/widgets/statistic/statistic_chart.dart';
import 'package:flutter/material.dart';

class ChartContainer extends StatelessWidget {
  const ChartContainer({
    super.key,
    required this.date,
    required this.mode,
  });

  final DateTime date;
  final ChartMode mode;

  Future<List<int>> _getReadingTimeData() {
    switch (mode) {
      case ChartMode.week:
        return selectReadingTimeOfWeek(date);
      case ChartMode.month:
        return selectReadingTimeOfMonth(date);
      case ChartMode.year:
        return selectReadingTimeOfYear(date);
    }
  }

  List<String> _getXLabels(BuildContext context, List<int> data) {
    switch (mode) {
      case ChartMode.week:
        return [
          L10n.of(context).statistic_monday,
          L10n.of(context).statistic_tuesday,
          L10n.of(context).statistic_wednesday,
          L10n.of(context).statistic_thursday,
          L10n.of(context).statistic_friday,
          L10n.of(context).statistic_saturday,
          L10n.of(context).statistic_sunday,
        ];
      case ChartMode.month:
        return List.generate(data.length, (i) {
          if ((i + 1) % 5 == 0 || i == 0) {
            return (i + 1).toString();
          }
          return '';
        });
      case ChartMode.year:
        return List.generate(12, (i) => (i + 1).toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: _getReadingTimeData(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return StatisticChart(
            readingTime: snapshot.data!,
            xLabels: _getXLabels(context, snapshot.data!),
          );
        } else {
          return const SizedBox(
            width: double.infinity,
            child: CircularProgressIndicator(),
          );
        }
      },
    );
  }
}