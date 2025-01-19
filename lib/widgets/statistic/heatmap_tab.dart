import 'package:anx_reader/enums/chart_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/providers/statistic_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeatmapTab extends ConsumerWidget {
  const HeatmapTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticData = ref.watch(statisticDataProvider);

    return Container(
      height: 400,
      padding: const EdgeInsets.fromLTRB(10, 0, 10, 5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        borderRadius: BorderRadius.circular(15),
      ),
      child: statisticData.when(
        data: (data) => Column(
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
                    selected: {data.mode},
                    onSelectionChanged: (Set<ChartMode> newSelection) {
                      ref
                          .read(statisticDataProvider.notifier)
                          .setMode(newSelection.first);
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
          ],
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Text('Error: $error'),
        ),
      ),
    );
  }
}
