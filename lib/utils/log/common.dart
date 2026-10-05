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

  /// 文件日志连续写入失败的次数。
  ///
  /// 日志写入失败**绝不能向外抛异常**：`AnxError` 的全局错误处理器会再次写日志，
  /// 一旦写入失败就会形成「写日志失败 → 记录该异常 → 又写日志失败」的死循环，
  /// 把事件循环占死，启动阶段永远等不到首帧（表现为进程在跑但没有任何窗口）。
  /// 因此这里失败即降级：连续失败 [_maxFileLogWriteFailures] 次后彻底停用文件日志。
  static int _fileLogWriteFailures = 0;
  static const int _maxFileLogWriteFailures = 3;

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
    try {
      final logParts = log.split('^*^');
      final level = stringToLevel(logParts[0]);
      final time = DateTime.parse(logParts[1].trim());
      final message = logParts[2];
      return AnxLog(level, time, message);
    } catch (e) {
      return AnxLog(Level.SEVERE, DateTime.now(), 'Parse log error: $e');
    }
  }

  static init() async {
    try {
      logFile = await getLogFile();
    } catch (e) {
      // 例如文件被另一个实例独占、或所在目录不可写
      logFile = null;
      if (kDebugMode) {
        print('AnxLog: cannot open log file, file logging disabled: $e');
      }
    }

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
      writeToFile(
          '${'${record.level.name}^*^ ${record.time}^*^ [${record.message}]$error,${record.stackTrace}'.replaceAll('\n', ' ')}\n');
    });
    if (Prefs().clearLogWhenStart) {
      clear();
    }
    info('Log file: ${logFile?.path ?? '(unavailable)'}');
  }

  /// 安全地把一行日志追加到日志文件；任何失败都只降级，不抛出。
  static void writeToFile(String line) {
    final file = logFile;
    if (file == null || _fileLogWriteFailures >= _maxFileLogWriteFailures) {
      return;
    }
    try {
      file.writeAsStringSync(line, mode: FileMode.append);
      _fileLogWriteFailures = 0;
    } catch (e) {
      _fileLogWriteFailures++;
      if (kDebugMode) {
        print('AnxLog: failed to write log file '
            '($_fileLogWriteFailures/$_maxFileLogWriteFailures): $e');
        if (_fileLogWriteFailures >= _maxFileLogWriteFailures) {
          print('AnxLog: file logging disabled for this session');
        }
      }
    }
  }

  static void clear() {
    try {
      logFile?.writeAsStringSync('');
      _fileLogWriteFailures = 0;
    } catch (e) {
      if (kDebugMode) {
        print('AnxLog: failed to clear log file: $e');
      }
    }
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
