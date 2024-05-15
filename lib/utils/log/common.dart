import 'dart:io';

import 'package:anx_reader/utils/log/string_to_level.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:logging/logging.dart';
import 'package:path_provider/path_provider.dart';

import '../get_path/log_file.dart';

class AnxLog {
  static final log = Logger('AnxReader');

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
    // INFO: 2024-05-15 15:55:15.003495: Log file: /data/user/0/com.anxcye.anx_reader/app_flutter/anx_reader.log
    final logParts = log.split('^*^');
    final level = stringToLevel(logParts[0]);
    final time = DateTime.parse(logParts[1].trim());
    final message = logParts[2];
    return AnxLog(level, time, message);
  }

  static init() async {
    final logFile = await getLogFile();

    Logger.root.level = Level.ALL;
    Logger.root.onRecord.listen((record) {
      if (kDebugMode) {
        print('${record.level.name}: ${record.time}: ${record.message}');
      }
      logFile.writeAsStringSync(
          '${record.level.name}^*^ ${record.time}^*^ ${record.message}\n',
          mode: FileMode.append);
    });
    clear();
    log.info('Log file: ${logFile.path}');
  }

  static clear() async {
    File logFile = await getLogFile();
    logFile.writeAsStringSync('');
  }
}
