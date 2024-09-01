import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/home_page/bookshelf_page.dart';
import 'package:anx_reader/page/home_page/notes_page.dart';
import 'package:anx_reader/page/home_page/settings_page.dart';
import 'package:anx_reader/page/home_page/statistics_page.dart';
import 'package:anx_reader/utils/check_update.dart';
import 'package:anx_reader/utils/load_default_font.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';

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
  void initState() {
    super.initState();
    initAnx();
  }

  Future<void> initAnx() async {
    AnxToast.init(context);
    checkUpdate(false);
    if (Prefs().webdavStatus){
      await AnxWebdav.init();
      await AnxWebdav.syncData(SyncDirection.both);
    }
    loadDefaultFont();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        if (constraints.maxWidth > 600) {
          return Scaffold(
            // floatingActionButton: FloatingActionButton(
            //   onPressed: () {
            //     checkUpdate(false);
            //   },
            //   child: const Icon(Icons.sync),
            // ),
            body: Row(
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
            ),
          );
        } else {
          return Scaffold(
            body: _pages[_currentIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onBottomTap,
              destinations: _bottomBarItems(),
            ),
            // ],
          );
        }
      },
    );
  }

  void _onBottomTap(index) {
    setState(() {
      _currentIndex = index;
    });
  }

  List<Map<String, dynamic>> _navBarItems() {
    return [
      {'icon': Icons.book, 'label': L10n.of(context).navBar_bookshelf},
      {'icon': Icons.show_chart, 'label': L10n.of(context).navBar_statistics},
      {'icon': Icons.note, 'label': L10n.of(context).navBar_notes},
      {'icon': Icons.settings, 'label': L10n.of(context).navBar_settings},
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
