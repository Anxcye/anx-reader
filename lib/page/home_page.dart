import 'dart:io';

import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/home_page/bookshelf_page.dart';
import 'package:anx_reader/page/home_page/notes_page.dart';
import 'package:anx_reader/page/home_page/settings_page.dart';
import 'package:anx_reader/page/home_page/statistics_page.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/check_update.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/load_default_font.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/providers/anx_webdav.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:receive_sharing_intent/receive_sharing_intent.dart';
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

  Future<void> initAnx() async {
    AnxToast.init(context);
    checkUpdate(false);
    if (Prefs().webdavStatus) {
      await AnxWebdav().init();
      await AnxWebdav().syncData(SyncDirection.both, ref);
    }
    loadDefaultFont();

    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.windows) {
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

    if (Platform.isAndroid || Platform.isIOS) {
      // receive sharing intent
      Future<void> handleShare(List<SharedMediaFile> value) async {
        List<File> files = [];
        for (var item in value) {
          final sourceFile = File(item.path);
          files.add(sourceFile);
        }
        importBookList(files, context, ref);
        ReceiveSharingIntent.instance.reset();
      }

      ReceiveSharingIntent.instance.getMediaStream().listen((value) {
        AnxLog.info(
            'share: Receive share intent: ${value.map((e) => e.toMap())}');
        if (value.isNotEmpty) {
          handleShare(value);
        }
      }, onError: (err) {
        AnxLog.severe('share: Receive share intent');
      });

      ReceiveSharingIntent.instance.getInitialMedia().then((value) {
        AnxLog.info(
            'share: Receive share intent: ${value.map((e) => e.toMap())}');
        if (value.isNotEmpty) {
          handleShare(value);
        }
      }, onError: (err) {
        AnxLog.severe('share: Receive share intent');
      });

      if (DBHelper.updatedDB) {
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
    }
  }

  @override
  Widget build(BuildContext context) {
    List<Widget> pages = [
      const BookshelfPage(),
      if (Prefs().bottomNavigatorShowStatistics) const StatisticPage(),
      if (Prefs().bottomNavigatorShowNote) const NotesPage(),
      const SettingsPage(),
    ];
    List<Map<String, dynamic>> navBarItems = [
      {
        'icon': EvaIcons.book_open,
          'label': L10n.of(context).navBar_bookshelf
        },
        if (Prefs().bottomNavigatorShowStatistics)
          {
            'icon': Icons.show_chart,
            'label': L10n.of(context).navBar_statistics
          },
        if (Prefs().bottomNavigatorShowNote)
          {'icon': Icons.note, 'label': L10n.of(context).navBar_notes},
        {
          'icon': EvaIcons.settings_2,
          'label': L10n.of(context).navBar_settings
        },
    ];  

    List<NavigationRailDestination> railBarItems = navBarItems.map((item) {
      return NavigationRailDestination(
        icon: Icon(item['icon'] as IconData),
        label: Text(item['label'] as String),
      );
    }).toList();

    List<NavigationDestination> bottomBarItems = navBarItems.map((item) {
      return NavigationDestination(
          icon: Icon(item['icon'] as IconData),
          label: item['label'] as String,
        );
    }).toList();

    return LayoutBuilder(
      builder: (context, constraints) {
        _expanded ??= constraints.maxWidth > 1000;
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
                  trailing: Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        IconButton(
                          alignment: Alignment.bottomLeft,
                          icon: const Icon(Icons.menu),
                          onPressed: () {
                            _expanded = !_expanded!;
                            setState(() {});
                          },
                        ),
                        const SizedBox(height: 20),
                      ],
                    ),
                  ),
                  extended: _expanded!,
                  selectedIndex: _currentIndex,
                  onDestinationSelected: _onBottomTap,
                  destinations: railBarItems,
                  labelType: _expanded!
                      ? NavigationRailLabelType.none
                      : NavigationRailLabelType.all,
                  backgroundColor: ElevationOverlay.applySurfaceTint(
                      Theme.of(context).colorScheme.surface,
                      Theme.of(context).colorScheme.primary,
                      1),
                ),
                Expanded(child: pages[_currentIndex]),
              ],
            ),
          );
        } else {
          return Scaffold(
            body: pages[_currentIndex],
            bottomNavigationBar: NavigationBar(
              selectedIndex: _currentIndex,
              onDestinationSelected: _onBottomTap,
              destinations: bottomBarItems,
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
}
