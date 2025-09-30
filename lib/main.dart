import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/window_info.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/service/tts/tts_handler.dart';
import 'package:anx_reader/utils/color_scheme.dart';
import 'package:anx_reader/utils/error/common.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:provider/provider.dart' as provider;
import 'package:window_manager/window_manager.dart';

final navigatorKey = GlobalKey<NavigatorState>();
late AudioHandler audioHandler;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs().initPrefs();
  if (Platform.isWindows) {
    await windowManager.ensureInitialized();
    final size = Size(
      Prefs().windowInfo.width,
      Prefs().windowInfo.height,
    );
    final offset = Offset(
      Prefs().windowInfo.x,
      Prefs().windowInfo.y,
    );

    WindowManager.instance.setTitle('Anx Reader');
    if (size.width > 0 && size.height > 0) {
      await WindowManager.instance.setPosition(offset);
      await WindowManager.instance.setSize(size);
    }
    await WindowManager.instance.show();
    await WindowManager.instance.focus();
  }

  initBasePath();
  AnxLog.init();
  AnxError.init();

  await DBHelper().initDB();

  Server().start();

  audioHandler = await AudioService.init(
    builder: () => TtsHandler(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.anx.reader.tts.channel.audio',
      androidNotificationChannelName: 'ANX Reader TTS',
      androidNotificationOngoing: true,
      androidStopForegroundOnPause: true,
    ),
  );

  SmartDialog.config.custom = SmartConfigCustom(
    maskColor: Colors.black.withAlpha(35),
    useAnimation: true,
    animationType: SmartAnimationType.centerFade_otherSlide,
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

class _MyAppState extends ConsumerState<MyApp>
    with WidgetsBindingObserver, WindowListener {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    windowManager.addListener(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  Future<void> onWindowMoved() async {
    await _updateWindowInfo();
  }

  @override
  Future<void> onWindowResized() async {
    await _updateWindowInfo();
  }

  Future<void> _updateWindowInfo() async {
    if (!Platform.isWindows) {
      return;
    }
    final windowOffset = await windowManager.getPosition();
    final windowSize = await windowManager.getSize();

    Prefs().windowInfo = WindowInfo(
      x: windowOffset.dx,
      y: windowOffset.dy,
      width: windowSize.width,
      height: windowSize.height,
    );
    AnxLog.info('onWindowClose: Offset: $windowOffset, Size: $windowSize');
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (Prefs().webdavStatus) {
        ref.read(syncProvider.notifier).syncData(SyncDirection.both, ref, trigger: SyncTrigger.auto);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (Platform.isIOS) {
        Server().start();
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
      ],
      child: provider.Consumer<Prefs>(
        builder: (context, prefsNotifier, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            scrollBehavior: ScrollConfiguration.of(context).copyWith(
              physics: const BouncingScrollPhysics(),
              // dragDevices: {
              //   PointerDeviceKind.touch,
              //   PointerDeviceKind.mouse,
              // },
            ),
            navigatorObservers: [FlutterSmartDialog.observer],
            builder: FlutterSmartDialog.init(),
            navigatorKey: navigatorKey,
            locale: prefsNotifier.locale,
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            title: 'Anx',
            themeMode: prefsNotifier.themeMode,
            theme: colorSchema(prefsNotifier, context, Brightness.light),
            darkTheme: colorSchema(prefsNotifier, context, Brightness.dark),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
