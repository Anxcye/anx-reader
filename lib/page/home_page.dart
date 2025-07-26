import 'dart:io';

import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/service/initialization_check.dart';
import 'package:anx_reader/page/home_page/bookshelf_page.dart';
import 'package:anx_reader/page/home_page/notes_page.dart';
import 'package:anx_reader/page/home_page/settings_page.dart';
import 'package:anx_reader/page/home_page/statistics_page.dart';
import 'package:anx_reader/service/receive_file/receive_share.dart';
import 'package:anx_reader/utils/check_update.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/load_default_font.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter_floating_bottom_bar/flutter_floating_bottom_bar.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

WebViewEnvironment? webViewEnvironment;

class HomePage extends ConsumerStatefulWidget {
  const HomePage({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _HomePageState();
}

class _HomePageState extends ConsumerState<HomePage> {
  int _currentIndex = 0;

  bool? _expanded;

  @override
  void initState() {
    super.initState();
    initAnx();
  }

  Future<void> _checkWindowsWebview() async {
    final availableVersion = await WebViewEnvironment.getAvailableVersion();
    AnxLog.info('WebView2 version: $availableVersion');

    if (availableVersion == null) {
      SmartDialog.show(
        builder: (context) => AlertDialog(
          title: const Icon(Icons.error),
          content: Text(L10n.of(context).webview2_not_installed),
          actions: [
            TextButton(
              onPressed: () => {
                launchUrl(
                    Uri.parse(
                        'https://developer.microsoft.com/en-us/microsoft-edge/webview2'),
                    mode: LaunchMode.externalApplication)
              },
              child: Text(L10n.of(context).webview2_install),
            ),
          ],
        ),
      );
    } else {
      webViewEnvironment = await WebViewEnvironment.create(
        settings: WebViewEnvironmentSettings(
            userDataFolder: (await getAnxTempDir()).path),
      );
    }
  }

  void _showDbUpdatedDialog() {
    SmartDialog.show(
      clickMaskDismiss: false,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).common_attention),
        content: Text(L10n.of(context).db_updated_tip),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(L10n.of(context).common_ok),
          ),
        ],
      ),
    );
  }

  Future<void> initAnx() async {
    AnxToast.init(context);
    checkUpdate(false);
    InitializationCheck.check();
    if (Prefs().webdavStatus) {
      await Sync().init();
      await Sync().syncData(SyncDirection.both, ref, trigger: SyncTrigger.auto);
    }
    loadDefaultFont();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
      await _checkWindowsWebview();
    }

    if (Platform.isAndroid || Platform.isIOS) {
      receiveShareIntent(ref);
    }

    if (DBHelper.updatedDB) {
      _showDbUpdatedDialog();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget pages(int index, ScrollController? controller) {
      final page = [
        BookshelfPage(controller: controller),
        if (Prefs().bottomNavigatorShowStatistics)
          StatisticPage(
            controller: controller,
          ),
        if (Prefs().bottomNavigatorShowNote) NotesPage(controller: controller),
        SettingsPage(controller: controller),
      ];
      return page[index];
    }

    List<Map<String, dynamic>> navBarItems = [
      {'icon': EvaIcons.book_open, 'label': L10n.of(context).navBar_bookshelf},
      if (Prefs().bottomNavigatorShowStatistics)
        {'icon': Icons.show_chart, 'label': L10n.of(context).navBar_statistics},
      if (Prefs().bottomNavigatorShowNote)
        {'icon': Icons.note, 'label': L10n.of(context).navBar_notes},
      {'icon': EvaIcons.settings_2, 'label': L10n.of(context).navBar_settings},
    ];

    List<NavigationRailDestination> railBarItems = navBarItems.map((item) {
      return NavigationRailDestination(
        icon: Icon(item['icon'] as IconData),
        label: Text(item['label'] as String),
      );
    }).toList();

    List<BottomNavigationBarItem> bottomBarItems = navBarItems.map((item) {
      return BottomNavigationBarItem(
        icon: Icon(item['icon'] as IconData),
        label: item['label'] as String,
      );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        _expanded ??= constraints.maxWidth > 1000;
        if (constraints.maxWidth > 600) {
          return Scaffold(
            extendBody: true,
            body: Row(
              children: [
                Container(
                  margin: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: ElevationOverlay.applySurfaceTint(
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.primary,
                      3,
                    ),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(20),
                    child: NavigationRail(
                      leading: Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children: [
                            Padding(
                              padding: const EdgeInsets.only(right: 2.0),
                              child: Image.asset(
                                width: 32,
                                height: 32,
                                'assets/icon/Anx-logo-tined.png',
                                color: Theme.of(context).colorScheme.secondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      groupAlignment: 0,
                      extended: false,
                      selectedIndex: _currentIndex,
                      onDestinationSelected: _onBottomTap,
                      destinations: railBarItems,
                      labelType: NavigationRailLabelType.all,
                      backgroundColor: Colors.transparent,
                      // elevation: 0,
                    ),
                  ),
                ),
                Expanded(child: pages(_currentIndex, null)),
              ],
            ),
          );
        } else {
          return Scaffold(
            extendBody: true,
            body: Stack(
              children: [
                BottomBar(
                  body: (_, controller) => pages(_currentIndex, controller),
                  hideOnScroll: true,
                  scrollOpposite: false,
                  curve: Curves.easeIn,
                  barColor: Colors.transparent,
                  iconDecoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.primary,
                    borderRadius: BorderRadius.circular(500),
                  ),
                  child: Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: ElevationOverlay.applySurfaceTint(
                        Theme.of(context).colorScheme.surface,
                        Theme.of(context).colorScheme.primary,
                        3,
                      ),
                      borderRadius: BorderRadius.circular(32),
                      boxShadow: [
                        BoxShadow(
                          color: Theme.of(context)
                              .colorScheme
                              .secondaryContainer,
                          blurRadius: 8,
                        ),
                      ],
                    ),
                    child: BottomNavigationBar(
                      enableFeedback: false,
                      type: BottomNavigationBarType.fixed,
                      landscapeLayout:
                          BottomNavigationBarLandscapeLayout.linear,
                      currentIndex: _currentIndex,
                      onTap: _onBottomTap,
                      items: bottomBarItems,
                      backgroundColor: Colors.transparent,
                      elevation: 0,
                      // height: 64,
                    ),
                  ),
                ),
              ],
            ),
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
}
