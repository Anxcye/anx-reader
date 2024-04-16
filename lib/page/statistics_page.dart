import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/main.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../dao/reading_time.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.navBarStatistics),
      ),
      body: Padding(
        padding: const EdgeInsets.all(18.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _totalReadTime(),
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                    child: _buildStatisticCard(
                        'Read {} Books', selectTotalNumberOfBook())),
                Expanded(
                    child: _buildStatisticCard(
                        'Read {} Days', selectTotalNumberOfDate())),
                Expanded(
                    child: _buildStatisticCard(
                        'Write {} Notes', selectTotalNumberOfNotes())),
              ],
            ),
            const SizedBox(height: 30),
            Charts(),
          ],
        ),
      ),
    );
  }
}

TextStyle totalReadTimeTextStyle() {
  return const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
}

TextStyle bigTextStyle() {
  return const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
}

TextStyle smallTextStyle() {
  return const TextStyle(
    fontSize: 16,
  );
}

Widget _totalReadTime() {
  return FutureBuilder<int>(
    future: selectTotalReadingTime(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        // 12 h 34 m
        int H = snapshot.data! ~/ 3600;
        int M = (snapshot.data! % 3600) ~/ 60;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            RichText(
              textAlign: TextAlign.start,
              text: TextSpan(
                style: DefaultTextStyle
                    .of(context)
                    .style,
                children: <TextSpan>[
                  TextSpan(text: '$H', style: totalReadTimeTextStyle()),
                  TextSpan(text: ' h ', style: bigTextStyle()),
                  TextSpan(text: '$M', style: totalReadTimeTextStyle()),
                  TextSpan(text: ' m', style: bigTextStyle()),
                ],
              ),
            ),
            Text(
              '${SharedPreferencesProvider().beginDate.toString().substring(
                  0, 10)} to now',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            )
          ],
        );
      } else {
        return const CircularProgressIndicator();
      }
    },
  );
}

Widget _buildStatisticCard(String title, Future<int> value) {
  return FutureBuilder<int>(
    future: value,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        var parts = title.split('{}');
        return
          // Card(
          // child:
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Center(
              child: RichText(
                text: TextSpan(
                  style: DefaultTextStyle
                      .of(context)
                      .style,
                  children: <TextSpan>[
                    TextSpan(text: parts[0], style: smallTextStyle()),
                    TextSpan(text: '${snapshot.data}', style: bigTextStyle()),
                    TextSpan(text: parts[1], style: smallTextStyle()),
                  ],
                ),
                textAlign: TextAlign.center,
              ),
            ),
            // ),
          );
      } else {
        return const CircularProgressIndicator();
      }
    },
  );
}

enum ChartMode { week, month, year }

class Charts extends StatefulWidget {
  @override
  _ChartsState createState() => _ChartsState();
}

class _ChartsState extends State<Charts> {
  ChartMode _currentMode = ChartMode.week;
  Widget currentChart =
  StatisticChart(); // You can change this based on _currentMode

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Card(
        child: Column(
          children: [
            const SizedBox(height: 10),
            SizedBox(
              height: 30,
              width: 300,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _chartModeButton(ChartMode.week, 'Week'),
                  const SizedBox(width: 15),
                  _chartModeButton(ChartMode.month, 'Month'),
                  const SizedBox(width: 15),
                  _chartModeButton(ChartMode.year, 'Year'),
                ],
              ),
            ),
            SizedBox(height: 10),
            Expanded(child: currentChart)
          ],
        ),
      ),
    );
  }

  Widget _chartModeButton(ChartMode mode, String text) {
    return Expanded(
      child: ElevatedButton(
        onPressed: () {
          setState(() {
            _currentMode = mode;
          });
        },
        style: ButtonStyle(
          backgroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
              if (_currentMode == mode) {
                return Theme
                    .of(context)
                    .colorScheme
                    .primary;
              }
              return Theme
                  .of(context)
                  .colorScheme
                  .surface;
            },
          ),
          foregroundColor: MaterialStateProperty.resolveWith<Color>(
                (Set<MaterialState> states) {
              if (_currentMode == mode) {
                return Theme
                    .of(context)
                    .colorScheme
                    .onPrimary;
              }
              return Theme
                  .of(context)
                  .colorScheme
                  .onSurface;
            },
          ),
        ),
        child: Text(text),
      ),
    );
  }
}

class StatisticChart extends StatelessWidget {
  List<int> readingTime;
  List<String> xLabels;
  Color bottomColor =
      Theme
          .of(navigatorKey.currentState!.context)
          .colorScheme
          .primary;
  Color topColor = Theme
      .of(navigatorKey.currentState!.context)
      .colorScheme
      .primary
      .withOpacity(0.5);

  StatisticChart({this.readingTime = const [6, 10, 14, 15, 13, 10, 16, 17],
    this.xLabels = const ['Mn', 'Te', 'Wd', 'Tu', 'Fr', 'St', 'Sn', 'xx']});

  @override
  Widget build(BuildContext context) {
    return BarChart(
      BarChartData(
        barTouchData: barTouchData,
        titlesData: titlesData,
        borderData: borderData,
        barGroups: barGroups,
        gridData: const FlGridData(show: false),
        alignment: BarChartAlignment.spaceAround,
        maxY: 20,
      ),
    );
  }

  BarTouchData get barTouchData {
    return BarTouchData(
      enabled: false,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (group) => Colors.transparent,
        tooltipPadding: EdgeInsets.zero,
        tooltipMargin: 8,
        getTooltipItem: (BarChartGroupData group,
            int groupIndex,
            BarChartRodData rod,
            int rodIndex,) {
          return BarTooltipItem(
            rod.toY.round().toString(),
            TextStyle(
              color: topColor,
              fontWeight: FontWeight.bold,
            ),
          );
        },
      ),
    );
  }

  FlTitlesData get titlesData =>
      FlTitlesData(
        show: true,
        bottomTitles: AxisTitles(
          sideTitles: SideTitles(
            showTitles: true,
            reservedSize: 30,
            getTitlesWidget: getTitles,
          ),
        ),
        leftTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        topTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
        rightTitles: const AxisTitles(
          sideTitles: SideTitles(showTitles: false),
        ),
      );

  FlBorderData get borderData =>
      FlBorderData(
        show: false,
      );

  LinearGradient get _barsGradient =>
      LinearGradient(
        colors: [
          bottomColor,
          topColor,
        ],
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
      );

  List<BarChartGroupData> get barGroups {
    List<BarChartGroupData> barGroups = [];
    for (int i = 0; i < readingTime.length; i++) {
      barGroups.add(
        BarChartGroupData(
          x: i,
          barRods: [
            BarChartRodData(
              toY: readingTime[i].toDouble(),
              gradient: _barsGradient,
            ),
          ],
          showingTooltipIndicators: [0],
        ),
      );
    }
    return barGroups;
  }

  SideTitleWidget getTitles(double value, TitleMeta meta) {
    var style = TextStyle(
      color: bottomColor,
      fontWeight: FontWeight.bold,
      fontSize: 14,
    );
    return SideTitleWidget(
        axisSide: meta.axisSide,
        child: Text(
          xLabels[value.toInt()],
          style: style,
        ));
  }
}
