import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';

String documentPath = '';

Future<String> getAnxDocumentsPath() async {
  final directory = await getApplicationDocumentsDirectory();
  switch(defaultTargetPlatform) {
    case TargetPlatform.android:
      return directory.path;
    case TargetPlatform.windows:
      return '${directory.path}\\AnxReader';
    default:
      throw Exception('Unsupported platform');
  }
}

Future<Directory> getAnxDocumentDir() async {
  return Directory(await getAnxDocumentsPath());
}

void initBasePath() async {
  Directory appDocDir = await getAnxDocumentDir();
  documentPath = appDocDir.path;
  debugPrint('documentPath: $documentPath');
  final fileDir = getFileDir();
  final coverDir = getCoverDir();
  final fontDir = getFontDir();
  if (!fileDir.existsSync()) {
    fileDir.createSync();
  }
  if (!coverDir.existsSync()) {
    coverDir.createSync();
  }
  if (!fontDir.existsSync()) {
    fontDir.createSync();
  }
}

String getBasePath(String path) {
  return '$documentPath/$path';
}


Directory getFontDir({String? path}){
  path ??= documentPath;
  return Directory('$path/font');
}


Directory getCoverDir({String? path}){
  path ??= documentPath;
  return Directory('$path/cover');
}

Directory getFileDir({String? path}){
  path ??= documentPath;
  return Directory('$path/file');
}

