import 'dart:ui';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/page/home_page/notes_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:flutter_gen/gen_l10n/app_localizations.dart';

final navigatorKey = GlobalKey<NavigatorState>();

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Prefs().initPrefs();

  Server().start();
  initBasePath();

  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => Prefs(),
        ),
        ChangeNotifierProvider(
          create: (_) => NotesDetailModel(),
        )
      ],
      child: Consumer<Prefs>(
        builder: (context, prefsNotifier, child) {
          return MaterialApp(
            navigatorKey: navigatorKey,
            locale: prefsNotifier.locale,
            localizationsDelegates: AppLocalizations.localizationsDelegates,
            supportedLocales: AppLocalizations.supportedLocales,
            title: 'Anx',
            themeMode: prefsNotifier.themeMode,
            theme: ThemeData(
              brightness: Brightness.light,
              colorScheme: ColorScheme.fromSeed(
                seedColor: prefsNotifier.themeColor,
                brightness: Brightness.light,
              ),
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: prefsNotifier.themeColor,
                brightness: Brightness.dark,
              ),
            ),
            home: const HomePage(),
          );
        },
      ),
    );
  }
}
