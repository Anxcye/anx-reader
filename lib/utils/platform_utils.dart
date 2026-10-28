import 'dart:io';

import 'package:flutter/foundation.dart';

enum AnxPlatformEnum { android, ios, macos, windows, linux, ohos }

class AnxPlatform {
  static AnxPlatformEnum get type {
    if (Platform.isAndroid && !kIsWeb) {
      return AnxPlatformEnum.android;
    }
    if (Platform.isIOS && !kIsWeb) {
      return AnxPlatformEnum.ios;
    }
    if (Platform.isMacOS && !kIsWeb) {
      return AnxPlatformEnum.macos;
    }
    if (Platform.isWindows && !kIsWeb) {
      return AnxPlatformEnum.windows;
    }
    if (Platform.isLinux && !kIsWeb) {
      return AnxPlatformEnum.linux;
    }
    try {
      if (Platform.operatingSystem == 'ohos') {
        return AnxPlatformEnum.ohos;
      }
    } catch (_) {
      // Platform.operatingSystem might throw if not available in some environments
    }
    throw UnsupportedError('Unsupported platform');
  }

  static bool get isAndroid => type == AnxPlatformEnum.android;
  static bool get isIOS => type == AnxPlatformEnum.ios;
  static bool get isMacOS => type == AnxPlatformEnum.macos;
  static bool get isWindows => type == AnxPlatformEnum.windows;
  static bool get isLinux => type == AnxPlatformEnum.linux;
  static bool get isOhos => type == AnxPlatformEnum.ohos;

  static bool get isMobile => isAndroid || isIOS || isOhos;

  static bool get isDesktop => isWindows || isMacOS || isLinux;
}
