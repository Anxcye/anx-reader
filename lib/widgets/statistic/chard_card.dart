import 'package:flutter/material.dart';

import 'week_month_year_widget.dart';

enum ChartMode { week, month, year }

class ChartCard extends StatefulWidget {
  const ChartCard({super.key});

  @override
  _ChartCardState createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  ChartMode _currentMode = ChartMode.week;
  Widget currentChart = WeekWidget();

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
            const SizedBox(height: 10),
            Expanded(
              child: currentChart,
            )
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
            switch (mode) {
              case ChartMode.week:
                currentChart = const WeekWidget();

                break;
              case ChartMode.month:
                currentChart = const MonthWidget();
                break;
              case ChartMode.year:
                currentChart = const YearWidget();
                break;
            }
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

