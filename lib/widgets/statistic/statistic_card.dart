import 'package:anx_reader/enums/chart_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/providers/statistic_data.dart';
import 'package:anx_reader/utils/date/week_of_year.dart';
import 'package:anx_reader/widgets/statistic/heatmap_chart.dart';
import 'package:anx_reader/widgets/statistic/statistic_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';

class StatisticCard extends ConsumerWidget {
  const StatisticCard({super.key});

  void _changeDate(
    WidgetRef ref,
    bool isPlus,
    ChartMode currentMode,
    DateTime currentDate,
  ) {
    DateTime newDate = currentDate;
    final durationMap = {
      ChartMode.week: () => isPlus
          ? currentDate.add(const Duration(days: 7))
          : currentDate.subtract(const Duration(days: 7)),
      ChartMode.month: () => DateTime(currentDate.year,
          isPlus ? currentDate.month + 1 : currentDate.month - 1),
      ChartMode.year: () => DateTime(
          isPlus ? currentDate.year + 1 : currentDate.year - 1,
          currentDate.month),
    };

    newDate = durationMap[currentMode]!();

    if (newDate.isAfter(DateTime.now())) {
      newDate = DateTime.now();
    } else if (newDate.isBefore(DateTime(2024))) {
      return;
    }

    ref.read(statisticDataProvider.notifier).setDate(newDate);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticData = ref.watch(statisticDataProvider);
    Widget segmentButton(data) => Row(
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
                  ButtonSegment<ChartMode>(
                    value: ChartMode.heatmap,
                    label: Text(L10n.of(context).statistic_all),
                    icon: const Icon(Icons.grid_view_rounded),
                  ),
                ],
                selected: {data.mode},
                onSelectionChanged: (Set<ChartMode> newSelection) {
                  ref
                      .read(statisticDataProvider.notifier)
                      .setMode(newSelection.first);
                },
              ),
            ),
          ],
        );

    Widget barChart(data) => SizedBox(
          height: 300,
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () =>
                        _changeDate(ref, false, data.mode, data.date),
                    icon: const Icon(EvaIcons.arrow_ios_back_outline),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () async {
                      final newDate = await showDatePicker(
                        context: context,
                        initialEntryMode: DatePickerEntryMode.calendarOnly,
                        firstDate: DateTime(2024),
                        lastDate: DateTime.now(),
                        initialDate: data.date,
                      );
                      if (newDate != null) {
                        ref
                            .read(statisticDataProvider.notifier)
                            .setDate(newDate);
                      }
                    },
                    child: Text(
                      data.mode == ChartMode.week
                          ? weekOfYear(data.date)
                          : data.mode == ChartMode.month
                              ? '${data.date.year}.${data.date.month}'
                              : data.date.year.toString(),
                    ),
                  ),
                  const Spacer(),
                  IconButton(
                    onPressed: () =>
                        _changeDate(ref, true, data.mode, data.date),
                    icon: const Icon(EvaIcons.arrow_ios_forward_outline),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Expanded(
                child: statisticData.when(
                  data: (data) => StatisticChart(
                    readingTime: data.readingTime,
                    xLabels: data.xLabels,
                  ),
                  loading: () => const Center(
                    child: CircularProgressIndicator(),
                  ),
                  error: (error, stack) => Center(
                    child: Text('Error: $error'),
                  ),
                ),
              )
            ],
          ),
        );
    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOutBack,
      alignment: Alignment.topCenter,
      child: Container(
        padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          borderRadius: BorderRadius.circular(15),
        ),
        child: statisticData.when(
            data: (data) => Column(
                  children: [
                    const SizedBox(height: 10),
                    segmentButton(data),
                    const SizedBox(height: 10),
                    if (data.mode == ChartMode.heatmap) const HeatmapChart(),
                    if (data.mode != ChartMode.heatmap) barChart(data),
                    // HeatmapChart(),
                  ],
                ),
            loading: () => const Center(
                  child: CircularProgressIndicator(),
                ),
            error: (error, stack) => throw error),
      ),
    );
  }
}
