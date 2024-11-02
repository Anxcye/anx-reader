import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/page/home_page/notes_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/utils/error/common.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Prefs().initPrefs();
  AnxLog.init();
  AnxError.init();

  await DBHelper().initDB();
  Server().start();
  initBasePath();

  runApp(const MyApp());
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.inactive) {
      if (Prefs().webdavStatus) {
        await AnxWebdav.syncData(SyncDirection.upload);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => Prefs(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotesDetailModel(),
        )
      ],
      child: Consumer<Prefs>(
        builder: (context, prefsNotifier, child) {
          return MaterialApp(
            navigatorObservers: [FlutterSmartDialog.observer],
            builder: FlutterSmartDialog.init(),
            navigatorKey: navigatorKey,
            locale: prefsNotifier.locale,
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            title: 'Anx',
            themeMode: prefsNotifier.themeMode,
            // theme: ThemeData(
            //   brightness: Brightness.light,
            //   colorScheme: ColorScheme.fromSeed(
            //     seedColor: prefsNotifier.themeColor,
            //     brightness: Brightness.light,
            //   ),
            // ).useSystemChineseFont(Brightness.light),
            theme: FlexThemeData.light(
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
              colorScheme: ColorScheme.fromSeed(
                seedColor: prefsNotifier.themeColor,
                // brightness: Brightness.light,
              ),
            ).useSystemChineseFont(Brightness.light),
            darkTheme: FlexThemeData.dark(
              useMaterial3: true,
              swapLegacyOnMaterial3: true,
              darkIsTrueBlack: prefsNotifier.trueDarkMode,
              colorScheme: ColorScheme.fromSeed(
                seedColor: prefsNotifier.themeColor,
                brightness: Brightness.dark,
              ),
            ).useSystemChineseFont(Brightness.dark),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
