import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/statistic/statistic_chart.dart';
import 'package:flutter/material.dart';


class YearWidget extends StatelessWidget {
  const YearWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: selectReadingTimeOfYear(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return StatisticChart(
            readingTime: snapshot.data!,
            xLabels: List.generate(12, (i) {
              return (i + 1).toString();
            }),
          );
        } else {
          return
            const SizedBox(
              width: double.infinity,
              child: CircularProgressIndicator(),
            );
        }
      },
    );
  }
}

class MonthWidget extends StatelessWidget {
  const MonthWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: selectReadingTimeOfMonth(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return StatisticChart(
            readingTime: snapshot.data!,
            xLabels: List.generate(snapshot.data!.length, (i) {
              if ((i + 1) % 5 == 0 || i == 0) {
                return (i + 1).toString();
              }
              return '';
            }),
          );
        } else {
          return
            const SizedBox(
              width: double.infinity,
              child: CircularProgressIndicator(),
            );
        }
      },
    );
  }
}

class WeekWidget extends StatelessWidget {
  const WeekWidget({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<int>>(
      future: selectReadingTimeOfWeek(DateTime.now()),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return StatisticChart(
            readingTime: snapshot.data!,
            xLabels: [
              L10n.of(context).statistic_monday,
              L10n.of(context).statistic_tuesday,
              L10n.of(context).statistic_wednesday,
              L10n.of(context).statistic_thursday,
              L10n.of(context).statistic_friday,
              L10n.of(context).statistic_saturday,
              L10n.of(context).statistic_sunday,
            ],
          );
        } else {
          return
            const SizedBox(
              width: double.infinity,
              child: CircularProgressIndicator(),
            );
        }
      },
    );
  }
}
