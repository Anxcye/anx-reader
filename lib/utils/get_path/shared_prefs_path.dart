import 'dart:io';

import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:flutter/foundation.dart';

Future<Directory> getAnxSharedPrefsDir() async {
  switch(defaultTargetPlatform) {
    case TargetPlatform.android:
      // com.example.app/shared_prefs
      final docPath = await getAnxDocumentsPath();
      final sharedPrefsDirPath = '${docPath.split('/app_flutter')[0]}/shared_prefs';
      return Directory(sharedPrefsDirPath);
    case TargetPlatform.windows:
      return Directory('${Directory.current.path}\\shared_prefs');
    default:
      throw Exception('Unsupported platform');
  }
}