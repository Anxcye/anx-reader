import 'dart:io';
import 'dart:ui' as ui;

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/reading_page/more_settings/other_settings.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    await (FontLoader('ReadingVisual')
          ..addFont(
              rootBundle.load('assets/fonts/SourceHanSerifSC-Regular.otf')))
        .load();
  });
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await Prefs().initPrefs();
  });

  for (final scale in [1.0, 1.8]) {
    testWidgets(
        'swipe page turning is an explicit setting at text scale $scale',
        (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final capture = GlobalKey();
      final longPress = Prefs().longPressSelectionMode;
      final animation = Prefs().pageTurnStyle;
      final actions = Prefs().selectionMenuActionOrder;
      await tester.pumpWidget(MaterialApp(
        theme: ThemeData(fontFamily: 'ReadingVisual'),
        localizationsDelegates: L10n.localizationsDelegates,
        supportedLocales: L10n.supportedLocales,
        builder: (context, child) => MediaQuery(
          data: MediaQuery.of(context)
              .copyWith(textScaler: TextScaler.linear(scale)),
          child: child!,
        ),
        home: Scaffold(
          body: RepaintBoundary(
            key: capture,
            child: const ColoredBox(
              color: Colors.white,
              child: SingleChildScrollView(child: OtherSettings()),
            ),
          ),
        ),
      ));
      await tester.pumpAndSettle();
      final setting = find.ancestor(
        of: find.text('Swipe to turn pages'),
        matching: find.byType(ListTile),
      );
      final toggle =
          find.descendant(of: setting, matching: find.byType(Switch));
      expect(tester.widget<Switch>(toggle).value, isFalse);
      expect(find.textContaining('swipe on text to select a sentence'),
          findsOneWidget);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(Prefs().swipeToTurnPage, isTrue);
      expect(Prefs().longPressSelectionMode, longPress);
      expect(Prefs().pageTurnStyle, animation);
      expect(Prefs().selectionMenuActionOrder, actions);
      await tester.tap(toggle);
      await tester.pumpAndSettle();
      expect(Prefs().swipeToTurnPage, isFalse);
      // Framework reports any layout exception at test completion.
      await tester.runAsync(() async {
        final boundary = capture.currentContext!.findRenderObject()!
            as RenderRepaintBoundary;
        final image = await boundary.toImage();
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        await File('/tmp/anx-gesture-settings-$scale.png')
            .writeAsBytes(bytes!.buffer.asUint8List());
        image.dispose();
      });
    });
  }
}
