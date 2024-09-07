import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';

import 'get_base_path.dart';

Future<String> getAnxDataBasesPath() async {
  switch (defaultTargetPlatform) {
    case TargetPlatform.android:
      final path = await getDatabasesPath();
      return path;
    case TargetPlatform.windows:
      final documentsPath = await getAnxDocumentsPath();
      return '$documentsPath\\databases';
    default:
      throw Exception('Unsupported platform');
  }
}

Future<Directory> getAnxDataBasesDir() async {
  return Directory(await getAnxDataBasesPath());
}
