import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/version_check_type.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/app_version.dart';
import 'package:flutter/cupertino.dart';
import 'package:anx_reader/page/onboarding_screen.dart';
import 'package:anx_reader/page/changelog_screen.dart';
import 'package:anx_reader/utils/log/common.dart';

class InitializationCheck {
  static String? _lastVersion;
  static String? _currentVersion;

  static Future<String> get lastVersion async {
    if (_lastVersion == null) {
      await _checkVersion();
    }
    return _lastVersion!;
  }

  static Future<String> get currentVersion async {
    if (_currentVersion == null) {
      await _checkVersion();
    }
    return _currentVersion!;
  }

  static Future<void> check() async {
    final result = await _checkVersion();
    if (result == VersionCheckType.firstLaunch) {
      _handleFirstLaunch();
    } else if (result == VersionCheckType.updated) {
      _handleUpdateAvailable();
    } else {
      _handleNormalStartup();
    }
  }

  static Future<VersionCheckType> _checkVersion() async {
    _lastVersion = Prefs().lastAppVersion;
    if (_lastVersion == null) {
      return VersionCheckType.firstLaunch;
    } else {
      _currentVersion = await getAppVersion();
      if (lastVersion != currentVersion) {
        return VersionCheckType.updated;
      } else {
        return VersionCheckType.normal;
      }
    }
  }

  static void _handleFirstLaunch() {
    AnxLog.info('First launch detected, showing onboarding');
    // wait 0.8 seconds to ensure the app is ready
    Future.delayed(const Duration(milliseconds: 800), () {
      showCupertinoSheet(
          context: navigatorKey.currentContext!,
          pageBuilder: (context) => OnboardingScreen(
                onComplete: () {},
              ));
    });
  }

  static Future<void> _handleUpdateAvailable() async {
    final lv = await lastVersion;
    final cv = await currentVersion;
    AnxLog.info('Version update detected: $lv -> $cv');
    Future.delayed(const Duration(milliseconds: 800), () {
      showCupertinoSheet(
        context: navigatorKey.currentContext!,
        pageBuilder: (context) => ChangelogScreen(
          lastVersion: lv,
          currentVersion: cv,
          onComplete: () {},
        ),
      );
    });
  }

  static void _handleNormalStartup() {
    AnxLog.info('Normal startup, proceeding to main app');
  }
}
