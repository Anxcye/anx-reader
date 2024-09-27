import 'dart:io';

import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

// Future<Directory> getAnxSharedPrefsDir() async {
//   switch(defaultTargetPlatform) {
//     case TargetPlatform.android:
//       // com.example.app/shared_prefs
//       final docPath = await getAnxDocumentsPath();
//       final sharedPrefsDirPath = '${docPath.split('/app_flutter')[0]}/shared_prefs';
//       return Directory(sharedPrefsDirPath);
//     case TargetPlatform.windows:
//       return Directory("${(await getApplicationSupportDirectory()).path}\\shared_preferences.json");
//     default:
//       throw Exception('Unsupported platform');
//   }
// }

String getSharedPrefsFileName() {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      return 'FlutterSharedPreferences.xml';
    case TargetPlatform.windows:
      return 'shared_preferences.json';
    default:
      throw Exception('Unsupported platform');
  }
}

Future<File> getAnxShredPrefsFile() async {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      final docPath = await getAnxDocumentsPath();
      final sharedPrefsDirPath =
          '${docPath.split('/app_flutter')[0]}/shared_prefs';
      return File('$sharedPrefsDirPath/${getSharedPrefsFileName()}');

    case TargetPlatform.windows:
      return File(
          "${(await getApplicationSupportDirectory()).path}\\${getSharedPrefsFileName()}");

    default:
      throw Exception('Unsupported platform');
  }
}
