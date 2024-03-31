import 'dart:ui';

import 'package:anx_reader/config/preferences.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init();
  await SharedPreferencesProvider().initPrefs();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => SharedPreferencesProvider(),
      child: Consumer<SharedPreferencesProvider>(
          builder: (context, prefsNotifier, child) {
        return MaterialApp(
          locale: prefsNotifier.locale,
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          title: 'Anx',
          themeMode: prefsNotifier.themeMode,
          theme: ThemeData(
            brightness: Brightness.light,
            colorScheme: ColorScheme.fromSeed(
                seedColor: prefsNotifier.themeColor,
                brightness: Brightness.light),
          ),
          darkTheme: ThemeData(
            brightness: Brightness.dark,
            colorScheme: ColorScheme.fromSeed(
                seedColor: prefsNotifier.themeColor,
                brightness: Brightness.dark),
          ),
          home: const HomePage(),
        );
      }),
    );
  }
}
