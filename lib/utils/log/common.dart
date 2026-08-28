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
  final String raw;

  AnxLog(this.level, this.time, this.message, {this.raw = ''});

  get color => level == Level.SEVERE
      ? Colors.red
      : level == Level.WARNING
          ? Colors.orange
          : Colors.grey;

  static AnxLog parse(String log) {
    try {
      final firstSeparator = log.indexOf('^*^');
      final secondSeparator = log.indexOf('^*^', firstSeparator + 3);
      if (firstSeparator < 1 || secondSeparator < 0) {
        throw const FormatException('Missing log separators');
      }
      final level = stringToLevel(log.substring(0, firstSeparator));
      final time = DateTime.parse(
        log.substring(firstSeparator + 3, secondSeparator).trim(),
      );
      final message = log.substring(secondSeparator + 3).trim();
      return AnxLog(level, time, message, raw: log);
    } catch (e) {
      return AnxLog(
        Level.SHOUT,
        DateTime.now(),
        'Unrecognized log entry: $log',
        raw: log,
      );
    }
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
            '$colorCode${record.level.name}: ${record.time}: ${record.message} \x1B[0m');
        if (record.error != null) {
          print('$colorCode${record.error} \x1B[0m');
        }
        if (record.stackTrace != null) {
          print('$colorCode${record.stackTrace} \x1B[0m');
        }
      }
      String error = record.error == null ? '' : ' : ${record.error}';
      logFile!.writeAsStringSync(
          '${'${record.level.name}^*^ ${record.time}^*^ [${record.message}]$error,${record.stackTrace}'.replaceAll('\n', ' ')}\n',
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
    stackTrace ??= StackTrace.current;
    log.severe(message, error, stackTrace);
  }
}
