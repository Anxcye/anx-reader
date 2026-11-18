import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/reading_page/style_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('Page curl persists by name and is restored from preferences', () async {
    SharedPreferences.setMockInitialValues({});
    final prefs = Prefs();
    await prefs.initPrefs();
    expect(prefs.pageTurnStyle, PageTurn.slide);

    prefs.pageTurnStyle = PageTurn.curl;
    expect(prefs.prefs.getString('pageTurnStyle'), 'curl');
    await prefs.prefs.reload();
    expect(prefs.pageTurnStyle, PageTurn.curl);
  });

  test('Unknown stored page turn modes fall back to slide', () async {
    SharedPreferences.setMockInitialValues({'pageTurnStyle': 'futureMode'});
    final prefs = Prefs();
    await prefs.initPrefs();
    expect(prefs.pageTurnStyle, PageTurn.slide);
    await prefs.prefs.setInt('pageTurnStyle', 10);
    expect(prefs.pageTurnStyle, PageTurn.slide);
  });

  testWidgets('Page curl is an available localized page turn option',
      (tester) async {
    await tester.pumpWidget(MaterialApp(
      locale: const Locale('en'),
      supportedLocales: L10n.supportedLocales,
      localizationsDelegates: L10n.localizationsDelegates,
      home: Builder(builder: (context) {
        return Text(PageTurn.values.last.getLabel(context));
      }),
    ));
    await tester.pumpAndSettle();
    expect(PageTurn.values, contains(PageTurn.curl));
    expect(find.text('Page Curl'), findsOneWidget);
  });
}
