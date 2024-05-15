import 'dart:io';

import 'package:path_provider/path_provider.dart';

Future<File> getLogFile() async {
  final logFileDir = await getApplicationDocumentsDirectory();
  final String logFilePath = '${logFileDir.path}/anx_reader.log';
  final logFile = File(logFilePath);
  if (!logFile.existsSync()) {
    logFile.createSync();
  }
  return logFile;
}