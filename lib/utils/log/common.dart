import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/log/string_to_level.dart';
import 'package:anx_reader/utils/get_path/log_file.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';


class AnxLog {
  static final log = Logger('AnxReader');
  static late File? logFile;

  Level level;
  DateTime time;
  String message;

  AnxLog(this.level, this.time, this.message);

  get color => level == Level.SEVERE
      ? Colors.red
      : level == Level.WARNING
          ? Colors.orange
          : Colors.grey;

  static AnxLog parse(String log) {
    final logParts = log.split('^*^');
    final level = stringToLevel(logParts[0]);
    final time = DateTime.parse(logParts[1].trim());
    final message = logParts[2];
    return AnxLog(level, time, message);
  }

  static init() async {
    logFile = await getLogFile();

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        String colorCode = '';
        if (record.level == Level.SEVERE) {
          colorCode = '\x1B[31m';
        } else if (record.level == Level.WARNING) {
          colorCode = '\x1B[33m';
        } else if (record.level == Level.INFO) {
          colorCode = '\x1B[34m';
        }
        print(
            '$colorCode${record.level.name}: ${record.time}: ${record.message} ');
        print('${record.error} \x1B[0m');
      }
      logFile!.writeAsStringSync(
          '${'${record.level.name}^*^ ${record.time}^*^ [${record.message}]:${record.error}'
                  .replaceAll('\n', ' ')}\n',
          mode: FileMode.append);
    });
    if (Prefs().clearLogWhenStart) {
      clear();
    }
    info('Log file: ${logFile!.path}');
  }

  static void clear() {
    logFile!.writeAsStringSync('');
  }

  static info(String message, [Object? error, StackTrace? stackTrace]) {
    log.info(message, error, stackTrace);
  }

  static warning(String message, [Object? error, StackTrace? stackTrace]) {
    log.warning(message, error, stackTrace);
  }

  static severe(String message, [Object? error, StackTrace? stackTrace]) {
    log.severe(message, error, stackTrace);
  }
}
