import 'dart:async';
import 'dart:io';

import 'package:anx_reader/utils/platform_utils.dart';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/window_info.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/page/migration_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/service/network/http_proxy_overrides.dart';
import 'package:anx_reader/service/tts/tts_handler.dart';
import 'package:anx_reader/utils/get_path/macos_migration.dart';
import 'package:anx_reader/utils/color_scheme.dart';
import 'package:anx_reader/utils/error/common.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/window_position_validator.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:audio_service/audio_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:heroine/heroine.dart';
import 'package:provider/provider.dart' as provider;
import 'package:window_manager/window_manager.dart';
import 'package:webview_cef/webview_cef.dart' as cef;

final navigatorKey = GlobalKey<NavigatorState>();
late AudioHandler audioHandler;
final heroineController = HeroineController();

/// Whether macOS data migration is needed (checked at startup)
bool _needsMigration = false;
MigrationCheckResult? _migrationCheckResult;

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs().initPrefs();
  HttpOverrides.global = AnxHttpProxyOverrides();

  // Initialize desktop window with validated position
  if (AnxPlatform.isDesktop) {
    await initializeDesktopWindow();
  }

  if (AnxPlatform.isLinux) {
    await cef.WebviewManager().initialize();
  }

  // Check if migration is needed before initializing paths
  if (AnxPlatform.isMacOS) {
    _migrationCheckResult = await checkMigrationNeeded();
    _needsMigration = _migrationCheckResult?.needsMigration ?? false;
  }

  // If no migration needed, initialize paths normally
  if (!_needsMigration) {
    initBasePath();
    AnxLog.init();
    AnxError.init();
    await DBHelper().initDB();
  }

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
    useAnimation: !Prefs().eInkMode,
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
  static const Locale _englishFallbackLocale = Locale('en');

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

  /// Guards against re-entering the shutdown flow: handing the close back to the
  /// OS makes the native side emit another `close` event.
  bool _closing = false;

  @override
  Future<void> onWindowClose() async {
    if (_closing) {
      return;
    }
    _closing = true;

    // 关闭窗口时先立即隐藏窗口：原先要等 Server/WebView2/数据库全部释放完
    // 才真正关闭窗口，期间窗口会长时间「无响应」（实测十几秒）。
    // 现在每一步都带超时兜底，任何一步卡住都不再拖住关闭流程。
    await _shutdownStep('hide window',
        () => windowManager.hide(), const Duration(seconds: 2));

    await _shutdownStep(
        'stop local server', () => Server().stop(), const Duration(seconds: 3));

    final environment = webViewEnvironment;
    webViewEnvironment = null;
    if (environment != null) {
      await _shutdownStep('dispose webview environment',
          () => environment.dispose(), const Duration(seconds: 5));
    }

    if (AnxPlatform.isLinux) {
      await _shutdownStep('quit CEF webview manager',
          () => cef.WebviewManager().quit(), const Duration(seconds: 5));
    }

    await _shutdownStep(
        'close database', () => DBHelper.close(), const Duration(seconds: 3));

    // 兜底：正常情况下窗口交还给系统后进程自己就会退出；万一没退干净就把进程结束掉，
    // 保证应用一定关得掉。
    Timer(const Duration(seconds: 3), () {
      AnxLog.warning('onWindowClose: graceful exit timed out, forcing exit');
      exit(0);
    });

    // 关键：不要把 windowManager.destroy() 当作退出手段。
    // 它在 Windows 上只是 PostQuitMessage(0)：窗口不销毁、引擎也不销毁，
    // 消息循环先停，之后才在 main() 返回时去销毁引擎；此时已经没有任何消息泵，
    // 引擎收尾必然空指针崩溃（0xc0000005 @ flutter_windows.dll+0x1e220），
    // 接着 WerFault 收集转储把进程再吊住约 10 秒，窗口一直是「无响应」。
    // 正确做法：取消关闭拦截，再 close() 把销毁交还给系统默认路径
    // （WM_CLOSE → DestroyWindow → WM_DESTROY），引擎在消息循环仍在运行时干净退役。
    AnxLog.info('onWindowClose: handing over to default close path');
    await _shutdownStep('hand over to default close path', () async {
      await windowManager.setPreventClose(false);
      await windowManager.close();
    }, const Duration(seconds: 2));
  }

  /// 执行一步关闭清理：记录耗时、设置超时；返回是否在超时内完成。
  Future<bool> _shutdownStep(
    String name,
    Future<void> Function() action,
    Duration timeout,
  ) async {
    final stopwatch = Stopwatch()..start();
    try {
      await action().timeout(timeout);
      AnxLog.info(
          'onWindowClose: $name done in ${stopwatch.elapsedMilliseconds}ms');
      return true;
    } catch (e) {
      AnxLog.warning('onWindowClose: $name failed or timed out after '
          '${stopwatch.elapsedMilliseconds}ms: $e');
      return false;
    }
  }

  @override
  Future<void> onWindowMoved() async {
    await _updateWindowInfo();
  }

  @override
  Future<void> onWindowMaximize() async {
    await _updateWindowInfo();
  }

  @override
  Future<void> onWindowUnmaximize() async {
    await _updateWindowInfo();
  }

  @override
  Future<void> onWindowResized() async {
    await _updateWindowInfo();
  }

  Future<void> _updateWindowInfo() async {
    if (!AnxPlatform.isDesktop) {
      return;
    }
    final windowOffset = await windowManager.getPosition();
    final windowSize = await windowManager.getSize();
    final isMaximized = await windowManager.isMaximized();

    Prefs().windowInfo = WindowInfo(
        x: windowOffset.dx,
        y: windowOffset.dy,
        width: windowSize.width,
        height: windowSize.height,
        isMaximized: isMaximized);
    AnxLog.info('onWindowClose: Offset: $windowOffset, Size: $windowSize');
  }

  @override
  Future<void> didChangeAppLifecycleState(AppLifecycleState state) async {
    if (state == AppLifecycleState.paused ||
        state == AppLifecycleState.hidden) {
      if (Prefs().webdavStatus) {
        ref
            .read(syncProvider.notifier)
            .syncData(SyncDirection.both, ref, trigger: SyncTrigger.auto);
      }
    } else if (state == AppLifecycleState.resumed) {
      if (AnxPlatform.isIOS) {
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
            navigatorObservers: [
              FlutterSmartDialog.observer,
              heroineController
            ],
            builder: FlutterSmartDialog.init(),
            navigatorKey: navigatorKey,
            locale: prefsNotifier.locale,
            localeListResolutionCallback: _resolveLocale,
            localizationsDelegates: L10n.localizationsDelegates,
            supportedLocales: L10n.supportedLocales,
            title: 'Anx Reader',
            themeMode: prefsNotifier.themeMode,
            theme: colorSchema(prefsNotifier, context, Brightness.light),
            darkTheme: colorSchema(prefsNotifier, context, Brightness.dark),
            home: _needsMigration
                ? _MigrationWrapper(
                    migrationCheckResult: _migrationCheckResult!)
                : const HomePage(),
          );
        },
      ),
    );
  }

  Locale _resolveLocale(
    List<Locale>? preferredLocales,
    Iterable<Locale> supportedLocales,
  ) {
    if (preferredLocales == null || preferredLocales.isEmpty) {
      return _englishFallbackLocale;
    }

    final Locale resolvedLocale = basicLocaleListResolution(
      preferredLocales,
      supportedLocales,
    );

    final bool hasMatch = preferredLocales.any((Locale preferredLocale) {
      return supportedLocales.any((Locale supportedLocale) {
        if (preferredLocale.languageCode != supportedLocale.languageCode) {
          return false;
        }

        final String? preferredCountryCode = preferredLocale.countryCode;
        final String? supportedCountryCode = supportedLocale.countryCode;

        return preferredCountryCode == null ||
            supportedCountryCode == null ||
            preferredCountryCode == supportedCountryCode;
      });
    });

    return hasMatch ? resolvedLocale : _englishFallbackLocale;
  }
}

/// Widget that wraps the migration flow on macOS.
/// Shows MigrationPage during migration, then navigates to HomePage.
class _MigrationWrapper extends StatefulWidget {
  final MigrationCheckResult migrationCheckResult;

  const _MigrationWrapper({required this.migrationCheckResult});

  @override
  State<_MigrationWrapper> createState() => _MigrationWrapperState();
}

class _MigrationWrapperState extends State<_MigrationWrapper> {
  bool _migrationComplete = false;

  Future<void> _onMigrationComplete() async {
    // Initialize paths and DB after migration
    initBasePath();
    AnxLog.init();
    AnxError.init();
    await DBHelper().initDB();

    if (mounted) {
      setState(() {
        _migrationComplete = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_migrationComplete) {
      return const HomePage();
    }
    return MigrationPage(onMigrationComplete: _onMigrationComplete);
  }
}
