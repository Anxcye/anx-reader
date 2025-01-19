import 'package:anx_reader/widgets/statistic/chart_tab.dart';
import 'package:anx_reader/widgets/statistic/heatmap_tab.dart';
import 'package:contentsize_tabbarview/contentsize_tabbarview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatisticCard extends ConsumerStatefulWidget {
  const StatisticCard({super.key});

  @override
  ConsumerState createState() => _StatisticCardState();
}

class _StatisticCardState extends ConsumerState<StatisticCard>
    with TickerProviderStateMixin {
  List<Tab> tabs = [
    Tab(text: 'Heatmap'),
    Tab(text: 'Chart'),
  ];

  List<Widget> children = [
    const HeatmapTab(),
    const ChartTab(),
  ];

  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        TabBar(
          isScrollable: true,
          controller: _tabController,
          tabs: tabs,
        ),
        const SizedBox(height: 10),
        ContentSizeTabBarView(
          controller: _tabController,
          children: children,
        ),
      ],
    );
  }
}
