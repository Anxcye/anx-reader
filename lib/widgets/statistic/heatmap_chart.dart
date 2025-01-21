import 'package:anx_reader/providers/heatmap_data.dart';
import 'package:anx_reader/providers/statistic_data.dart';
import 'package:flutter/material.dart';
import 'package:flutter_heatmap_calendar/flutter_heatmap_calendar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HeatmapChart extends ConsumerWidget {
  const HeatmapChart({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticData = ref.watch(heatmapDataProvider);

    return HeatMap(
      showColorTip: false,
      blockBorder: Border.all(
        color: Colors.black12,
        style: BorderStyle.solid,
        width: 0.25,
        strokeAlign: BorderSide.strokeAlignOutside,
      ),
      defaultColor: Theme.of(context).colorScheme.surface,
      datasets: statisticData.when(
          data: (data) => data, loading: () => {}, error: (error, stack) => {}),
      colorMode: ColorMode.opacity,
      showText: false,
      scrollable: true,
      colorsets: {
        1: Theme.of(context).colorScheme.primary,
      },
      onClick: (value) {
        ref.read(statisticDataProvider.notifier).setIsSelectingDay(true, value);
      },
    );
  }
}
