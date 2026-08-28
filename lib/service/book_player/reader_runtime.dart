import 'dart:io';

import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class ReaderRuntime {
  ReaderRuntime._();

  static Future<void>? _readyFuture;

  static Future<void> ensureReady() {
    return _readyFuture ??= _ensureReady().catchError((Object error) {
      _readyFuture = null;
      throw error;
    });
  }

  static Future<void> _ensureReady() async {
    await Server().ensureStarted();
    if (!Platform.isWindows || webViewEnvironment != null) return;

    final version = await WebViewEnvironment.getAvailableVersion();
    if (version == null) {
      throw StateError('WebView2 Runtime is not installed');
    }
    webViewEnvironment = await WebViewEnvironment.create(
      settings: WebViewEnvironmentSettings(
        userDataFolder: (await getAnxTempDir()).path,
      ),
    );
  }
}
