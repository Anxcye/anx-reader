import 'dart:io';

import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/platform_utils.dart';
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
  switch (AnxPlatform.type) {
    case AnxPlatformEnum.android:
      return 'FlutterSharedPreferences.xml';
    case AnxPlatformEnum.windows:
    case AnxPlatformEnum.linux:
      return 'shared_preferences.json';
    case AnxPlatformEnum.macos:
    case AnxPlatformEnum.ios:
      return 'com.anxcye.anxReader.plist';
    case AnxPlatformEnum.ohos:
      return 'FlutterSharedPreferences';
  }
}

Future<File> getAnxShredPrefsFile() async {
  switch (AnxPlatform.type) {
    case AnxPlatformEnum.android:
      final docPath = await getAnxDocumentsPath();
      final sharedPrefsDirPath =
          '${docPath.split('/app_flutter')[0]}/shared_prefs';
      return File('$sharedPrefsDirPath/${getSharedPrefsFileName()}');

    case AnxPlatformEnum.windows:
    case AnxPlatformEnum.linux:
      return File(
          "${(await getApplicationSupportDirectory()).path}${Platform.pathSeparator}${getSharedPrefsFileName()}");
    case AnxPlatformEnum.macos:
      final baseDir =
          '${(await getAnxDocumentsPath()).split('Documents')[0]}Library/Preferences';
      return File("$baseDir/${getSharedPrefsFileName()}");
    case AnxPlatformEnum.ios:
      final baseDir =
          '${((await getApplicationDocumentsDirectory()).path).split('Documents')[0]}Library/Preferences';
      return File("$baseDir/${getSharedPrefsFileName()}");
    case AnxPlatformEnum.ohos:
      final docPath = await getAnxDocumentsPath();
      final sharedPrefsDirPath = '${docPath.split('/base')[0]}/preferences';
      return File('$sharedPrefsDirPath/${getSharedPrefsFileName()}');
  }
}
