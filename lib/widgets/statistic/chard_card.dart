import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/statistic/week_month_year_widget.dart';
import 'package:flutter/material.dart';

enum ChartMode { week, month, year }

class ChartCard extends StatefulWidget {
  const ChartCard({super.key});

  @override
  _ChartCardState createState() => _ChartCardState();
}

class _ChartCardState extends State<ChartCard> {
  ChartMode _currentMode = ChartMode.week;
  Widget currentChart = const WeekWidget();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 300,
      child: Card(
        shadowColor: Colors.transparent,
        child: Column(
          children: [
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SegmentedButton<ChartMode>(
                      segments: <ButtonSegment<ChartMode>>[
                        ButtonSegment<ChartMode>(
                          value: ChartMode.week,
                          label: Text(L10n.of(context).statistic_week),
                          icon: const Icon(Icons.calendar_view_week),
                        ),
                        ButtonSegment<ChartMode>(
                          value: ChartMode.month,
                          label: Text(L10n.of(context).statistic_month),
                          icon: const Icon(Icons.calendar_month),
                        ),
                        ButtonSegment<ChartMode>(
                          value: ChartMode.year,
                          label: Text(L10n.of(context).statistic_year),
                          icon: const Icon(Icons.calendar_today),
                        ),
                      ],
                      selected: {_currentMode},
                      onSelectionChanged: (Set<ChartMode> newSelection) {
                        setState(() {
                          _currentMode = newSelection.first;
                          switch (_currentMode) {
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
                    ),
                  ),
                ),
              ],
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
}
