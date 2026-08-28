import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/device_display_profile.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/settings/device_display_profile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('device profile card fits a narrow phone and switches locally',
      (tester) async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        locale: Locale('en'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        home: Scaffold(
          body: SingleChildScrollView(
            padding: EdgeInsets.all(8),
            child: DeviceDisplayProfileCard(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.text('Device-only setting · not restored from another device'),
        findsOneWidget);

    await tester.tap(find.text('E-ink').last);
    await tester.pumpAndSettle();

    expect(Prefs().deviceDisplayProfile, DeviceDisplayProfile.eInk);
    expect(tester.takeException(), isNull);
  });
}
