import 'dart:io';

import 'package:path_provider/path_provider.dart';

String documentPath = '';

void initBasePath() async {
  Directory appDocDir = await getApplicationDocumentsDirectory();
  documentPath = appDocDir.path;
  final fileDir = Directory('${appDocDir.path}/file');
  final coverDir = Directory('${appDocDir.path}/cover');
  if (!fileDir.existsSync()) {
    fileDir.createSync();
  }
  if (!coverDir.existsSync()) {
    coverDir.createSync();
  }
}

String getBasePath(String path) {
  return '$documentPath/$path';
}