import 'dart:io';
import 'dart:ui';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/window_info.dart';
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
    builder: () => Tts(),
    config: const AudioServiceConfig(
      androidNotificationChannelId: 'com.anxcye.anx_reader.channel.audio',
      androidNotificationChannelName: 'TTS playback',
      androidNotificationOngoing: true,
    ),
  );

  SmartDialog.config.custom = SmartConfigCustom(
    maskColor: Colors.black.withOpacity(0.35),
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
          // Color dragToMoveColor = ColorScheme.fromSeed(
          //   seedColor: prefsNotifier.themeColor,
          //   brightness: prefsNotifier.themeMode == ThemeMode.light
          //       ? Brightness.light
          //       : prefsNotifier.themeMode == ThemeMode.dark
          //           ? Brightness.dark
          //           : MediaQuery.platformBrightnessOf(context),
          // ).surface;

          // Widget dragToMoveArea = DragToMoveArea(
          //   child: MaterialApp(
          //     debugShowCheckedModeBanner: false,
          //     home: Container(
          //         color: dragToMoveColor,
          //         child: Row(
          //           mainAxisAlignment: MainAxisAlignment.end,
          //           children: [
          //             IconButton(
          //                 onPressed: () {
          //                   windowManager.minimize();
          //                 },
          //                 icon: const Icon(EvaIcons.minus)),
          //             IconButton(
          //                 onPressed: () async {
          //                   if (await WindowManager.instance.isMaximized()) {
          //                     windowManager.unmaximize();
          //                   } else {
          //                     windowManager.maximize();
          //                   }
          //                 },
          //                 icon: const Icon(EvaIcons.square_outline)),
          //             IconButton(
          //               onPressed: () {
          //                 windowManager.close();
          //               },
          //               icon: const Icon(EvaIcons.close_outline),
          //             ),
          //           ],
          //         )),
          //   ),
          // );

          return Column(
            children: [
              // dragToMoveArea,
              Expanded(
                child: MaterialApp(
                  debugShowCheckedModeBanner: false,
                  scrollBehavior: ScrollConfiguration.of(context).copyWith(
                    physics: const BouncingScrollPhysics(),
                    dragDevices: {
                      PointerDeviceKind.touch,
                      PointerDeviceKind.mouse,
                    },
                  ),
                  navigatorObservers: [FlutterSmartDialog.observer],
                  builder: FlutterSmartDialog.init(),
                  navigatorKey: navigatorKey,
                  locale: prefsNotifier.locale,
                  localizationsDelegates: L10n.localizationsDelegates,
                  supportedLocales: L10n.supportedLocales,
                  title: 'Anx',
                  themeMode: prefsNotifier.themeMode,
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
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
