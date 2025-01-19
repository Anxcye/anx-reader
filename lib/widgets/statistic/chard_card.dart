import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/date/week_of_year.dart';
import 'package:anx_reader/widgets/statistic/week_month_year_widget.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

enum ChartMode { week, month, year }

class ChartCard extends StatefulWidget {
  const ChartCard({super.key});

  @override
  ChartCardState createState() => ChartCardState();
}

class ChartCardState extends State<ChartCard> {
  ChartMode _currentMode = ChartMode.week;
  DateTime _currentDate = DateTime.now();

  @override
  Widget build(BuildContext context) {
    void changeCurrentDate(bool isPlus) {
      DateTime oldDate = _currentDate;
      switch (_currentMode) {
        case ChartMode.week:
          _currentDate = isPlus
              ? _currentDate.add(const Duration(days: 7))
              : _currentDate.subtract(const Duration(days: 7));
          break;
        case ChartMode.month:
          _currentDate = isPlus
              ? DateTime(_currentDate.year, _currentDate.month + 1)
              : DateTime(_currentDate.year, _currentDate.month - 1);
          break;
        case ChartMode.year:
          _currentDate = isPlus
              ? DateTime(_currentDate.year + 1, _currentDate.month)
              : DateTime(_currentDate.year - 1, _currentDate.month);
          break;
      }
      if (_currentDate.isAfter(DateTime.now())) {
        _currentDate = DateTime.now();
      } else if (_currentDate.isBefore(DateTime(2024))) {
        _currentDate = oldDate;
      }
      setState(() {});
    }

    return Container(
      height: 300,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(15),
      ),
      child: Column(
        children: [
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
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
                    _currentMode = newSelection.first;
                    setState(() {});
                  },
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  changeCurrentDate(false);
                },
                icon: const Icon(EvaIcons.arrow_ios_back_outline),
              ),
              const Spacer(),
              TextButton(
                onPressed: () async {
                  _currentDate = await showDatePicker(
                        context: context,
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        initialDate: _currentDate,
                      ) ??
                      _currentDate;
                  setState(() {});
                },
                child: Text(
                  _currentMode == ChartMode.week
                      ? weekOfYear(_currentDate)
                      : _currentMode == ChartMode.month
                          ? '${_currentDate.year}.${_currentDate.month}'
                          : _currentDate.year.toString(),
                ),
              ),
              const Spacer(),
              IconButton(
                onPressed: () {
                  changeCurrentDate(true);
                },
                icon: const Icon(EvaIcons.arrow_ios_forward_outline),
              ),
              // IconButton(
              //   onPressed: () {},
              //   icon: const Icon(EvaIcons.calendar),
              // ),
            ],
          ),
          const SizedBox(height: 10),
          Expanded(
            child: ChartContainer(
              date: _currentDate,
              mode: _currentMode,
            ),
          )
        ],
      ),
    );
  }
}
