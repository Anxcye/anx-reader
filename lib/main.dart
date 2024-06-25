import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/page/home_page/notes_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/utils/check_update.dart';
import 'package:anx_reader/utils/error/common.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';


final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Prefs().initPrefs();
  AnxLog.init();
  AnxError.init();

  Server().start();
  initBasePath();
  checkUpdate(false);

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
            navigatorKey: navigatorKey,
            locale: prefsNotifier.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'Anx',
            themeMode: prefsNotifier.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: prefsNotifier.themeColor,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: prefsNotifier.themeColor,
                brightness: Brightness.dark,
              ),
            ),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
