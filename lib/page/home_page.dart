import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/page/bookshelf_page.dart';
import 'package:anx_reader/page/notes_page.dart';
import 'package:anx_reader/page/settinds_page/settings_page.dart';
import 'package:anx_reader/page/statistics_page.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  int _currentIndex = 0;
  final List<Widget> _pages = [
    const BookshelfPage(),
    const StatisticPage(),
    const NotesPage(),
    const SettingsPage(),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (constraints.maxWidth > 600) {
            return Row(
              children: [
                NavigationRail(
                  extended: constraints.maxWidth > 800,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onBottomTap,
                  destinations: _railBarItems(),
                  backgroundColor: ElevationOverlay.applySurfaceTint(
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.primary,
                      1),
                ),
                Expanded(child: _pages[_currentIndex]),
              ],
            );
          } else {
            return Column(
              children: [
                Expanded(child: _pages[_currentIndex]),
                 NavigationBar(
                    selectedIndex: _currentIndex,
                    onDestinationSelected: _onBottomTap,
                    destinations: _bottomBarItems(),
                  ),
              ],
            );
          }
        },
      ),
    );
  }

  void _onBottomTap(index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Map<String, dynamic>> _navBarItems() {
    return [
      {'icon': Icons.book, 'label': context.navBarBookshelf},
      {'icon': Icons.show_chart, 'label': context.navBarStatistics},
      {'icon': Icons.note, 'label': context.navBarNotes},
      {'icon': Icons.settings, 'label': context.navBarSettings},
    ];
  }

  List<NavigationRailDestination> _railBarItems() {
    return _navBarItems().map((item) {
      return NavigationRailDestination(
        icon: Icon(item['icon'] as IconData),
        label: Text(item['label'] as String),
      );
    }).toList();
  }

  List<NavigationDestination> _bottomBarItems() {
    return _navBarItems().map((item) {
      return NavigationDestination(
        icon: Icon(item['icon'] as IconData),
        label: item['label'] as String,
      );
    }).toList();
  }
}
