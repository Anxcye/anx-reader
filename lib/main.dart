import 'package:anx_reader/config/preferences.dart';
import 'package:anx_reader/config/theme_data.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Preferences.init();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => ThemeNotifier()..loadThemeFromPrefs(),
      child: Consumer<ThemeNotifier>(builder: (context, themeNotifier, child) {
        return MaterialApp(
          title: 'Anx Reader',
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: themeNotifier.themeColor),
          ),
          home: const HomePage(),
        );
      }),
    );
  }
}
