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
      // return '${directory.path}\\AnxReader';
      return (await getApplicationSupportDirectory()).path;
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
  // the path that in database using "/"
  path.replaceAll("/", Platform.pathSeparator);
  return '$documentPath${Platform.pathSeparator}$path';
}


Directory getFontDir({String? path}){
  path ??= documentPath;
  return Directory('$path${Platform.pathSeparator}font');
}


Directory getCoverDir({String? path}){
  path ??= documentPath;
  return Directory('$path${Platform.pathSeparator}cover');
}

Directory getFileDir({String? path}){
  path ??= documentPath;
  return Directory('$path${Platform.pathSeparator}file');
}

