import 'dart:io';
import 'package:anx_reader/utils/platform_utils.dart';

import 'package:sqflite/sqflite.dart';

import 'get_base_path.dart';

Future<String> getAnxDataBasesPath() async {
  switch (AnxPlatform.type) {
    case AnxPlatformEnum.android:
    case AnxPlatformEnum.ohos:
      final path = await getDatabasesPath();
      return path;
    case AnxPlatformEnum.windows:
    case AnxPlatformEnum.linux:
    case AnxPlatformEnum.macos:
    case AnxPlatformEnum.ios:
      final documentsPath = await getAnxDocumentsPath();
      return '$documentsPath${Platform.pathSeparator}databases';
  }
}

Future<Directory> getAnxDataBasesDir() async {
  return Directory(await getAnxDataBasesPath());
}
