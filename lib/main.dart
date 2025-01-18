import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/page/home_page/notes_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/service/tts.dart';
import 'package:anx_reader/utils/error/common.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/providers/anx_webdav.dart';
import 'package:audio_service/audio_service.dart';
import 'package:chinese_font_library/chinese_font_library.dart';
import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart' as provider;

final navigatorKey = GlobalKey<NavigatorState>();
late AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Prefs().initPrefs();
  AnxLog.init();
  AnxError.init();

  await DBHelper().initDB();
  Server().start();
  initBasePath();

  audioHandler = await AudioService.init(
    builder: () => Tts(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.anxcye.anx_reader.channel.audio',
      androidNotificationChannelName: 'TTS playback',
      androidNotificationOngoing: true,
    ),
  );

  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<ConsumerStatefulWidget> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
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
        state == AppLifecycleState.hidden) {
      if (Prefs().webdavStatus) {
        ref
            .read(anxWebdavProvider.notifier)
            .syncData(SyncDirection.upload, ref);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return provider.MultiProvider(
      providers: [
        provider.ChangeNotifierProvider(
          create: (_) => Prefs(),
        ),
        provider.ChangeNotifierProvider(
          create: (_) => NotesDetailModel(),
        )
      ],
      child: provider.Consumer<Prefs>(
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
