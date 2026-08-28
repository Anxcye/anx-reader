import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/app_theme_mode.dart';
import 'package:anx_reader/enums/code_highlight_theme.dart';
import 'package:anx_reader/enums/device_display_profile.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/widgets/reading_page/style_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('migrates legacy e-ink settings to a local device profile', () async {
    SharedPreferences.setMockInitialValues({
      'themeMode': 'dark',
      'eInkMode': true,
    });

    await Prefs().initPrefs();

    expect(Prefs().deviceDisplayProfile, DeviceDisplayProfile.eInk);
    expect(Prefs().appThemeMode, AppThemeMode.dark);
    expect(Prefs().effectiveThemeMode, ThemeMode.light);
    expect(Prefs().prefs.containsKey('eInkMode'), isFalse);
  });

  test('e-ink uses temporary reader overrides without replacing preferences',
      () async {
    SharedPreferences.setMockInitialValues({
      'themeMode': 'light',
      'pageTurnStyle': PageTurn.scroll.name,
      'codeHighlightTheme': CodeHighlightThemeEnum.github.code,
      'readTheme': ReadTheme(
        backgroundColor: 'FFEEE8D5',
        textColor: 'FF123456',
        backgroundImagePath: '/paper.png',
      ).toJson(),
    });
    await Prefs().initPrefs();

    await Prefs().saveDeviceDisplayProfile(DeviceDisplayProfile.eInk);

    expect(Prefs().effectiveReadTheme.backgroundColor, 'FFFFFFFF');
    expect(Prefs().effectiveReadTheme.textColor, 'FF000000');
    expect(Prefs().effectivePageTurnStyle, PageTurn.noAnimation);
    expect(Prefs().effectiveCodeHighlightTheme, CodeHighlightThemeEnum.off);

    await Prefs().saveDeviceDisplayProfile(DeviceDisplayProfile.standard);

    expect(Prefs().readTheme.backgroundColor, 'FFEEE8D5');
    expect(Prefs().readTheme.textColor, 'FF123456');
    expect(Prefs().pageTurnStyle, PageTurn.scroll);
    expect(Prefs().codeHighlightTheme, CodeHighlightThemeEnum.github);
  });

  test('display hardware and color preferences remain independent', () async {
    SharedPreferences.setMockInitialValues({
      'themeMode': AppThemeMode.dark.code,
      'trueDarkMode': true,
    });
    await Prefs().initPrefs();

    await Prefs().saveDeviceDisplayProfile(DeviceDisplayProfile.eInk);
    expect(Prefs().isEInkMode, isTrue);
    expect(Prefs().appThemeMode, AppThemeMode.dark);
    expect(Prefs().effectiveThemeMode, ThemeMode.light);
    expect(Prefs().trueDarkMode, isTrue);
    expect(Prefs().effectiveTrueDarkMode, isFalse);

    await Prefs().saveDeviceDisplayProfile(DeviceDisplayProfile.standard);
    expect(Prefs().appThemeMode, AppThemeMode.dark);
    expect(Prefs().effectiveTrueDarkMode, isTrue);
  });

  test('migrates the legacy combined e-ink theme to a light color preference',
      () async {
    SharedPreferences.setMockInitialValues({
      'themeMode': AppThemeMode.eInk.code,
    });
    await Prefs().initPrefs();

    expect(Prefs().deviceDisplayProfile, DeviceDisplayProfile.eInk);
    expect(Prefs().appThemeMode, AppThemeMode.light);
    expect(Prefs().effectiveThemeMode, ThemeMode.light);
  });

  test('device display preferences are excluded from backup restore', () async {
    SharedPreferences.setMockInitialValues({
      'deviceDisplayProfile': DeviceDisplayProfile.eInk.code,
      'themeMode': AppThemeMode.light.code,
      'themeColor': 0xFF00FF00,
      'trueDarkMode': false,
    });
    await Prefs().initPrefs();

    final backup = await Prefs().buildPrefsBackupMap();
    expect(backup, isNot(contains('deviceDisplayProfile')));
    expect(backup, isNot(contains('themeMode')));
    expect(backup, isNot(contains('themeColor')));
    expect(backup, isNot(contains('trueDarkMode')));

    await Prefs().applyPrefsBackupMap({
      'deviceDisplayProfile': {'type': 'string', 'value': 'standard'},
      'themeMode': {'type': 'string', 'value': 'dark'},
      'themeColor': {'type': 'int', 'value': 0xFFFF0000},
      'trueDarkMode': {'type': 'bool', 'value': true},
    });
    expect(Prefs().deviceDisplayProfile, DeviceDisplayProfile.eInk);
    expect(Prefs().appThemeMode, AppThemeMode.light);
    expect(Prefs().themeColor.toARGB32(), 0xFF00FF00);
    expect(Prefs().trueDarkMode, isFalse);
  });
}
