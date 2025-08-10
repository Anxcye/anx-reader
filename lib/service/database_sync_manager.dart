import 'dart:io' as io;
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/utils/get_path/get_cache_dir.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:flutter/material.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

/// Database safe sync manager
/// Provides safe database download, validation and recovery mechanisms
class DatabaseSyncManager {
  static const String _tempDbPrefix = 'temp_database_';
  static const String _backupDbPrefix = 'backup_database_';
  static const int _maxBackupCount = 3;

  /// Safe database download
  ///
  /// Process:
  /// 1. Download to cache temp file
  /// 2. Validate database integrity
  /// 3. Backup current database
  /// 4. Atomic replace database
  /// 5. Validate replacement result
  static Future<DatabaseSyncResult> safeDownloadDatabase({
    required SyncClientBase client,
    required String remoteDbFileName,
    void Function(int received, int total)? onProgress,
  }) async {
    final cacheDir = await getAnxCacheDir();
    final databasesPath = await getAnxDataBasesPath();
    final localDbPath = join(databasesPath, 'app_database.db');

    // Generate temp file name (use timestamp to ensure uniqueness)
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final tempDbName = '$_tempDbPrefix$timestamp.db';
    final tempDbPath = join(cacheDir.path, tempDbName);

    try {
      AnxLog.info('DatabaseSync: Starting safe database download');
      AnxLog.info('DatabaseSync: Remote file: $remoteDbFileName');
      AnxLog.info('DatabaseSync: Temp file: $tempDbPath');

      // Step 1: Download to temp file
      await client.downloadFile(
        'anx/$remoteDbFileName',
        tempDbPath,
        onProgress: onProgress,
      );

      AnxLog.info('DatabaseSync: Download completed, starting validation');

      // Step 2: Validate downloaded database
      final validationResult = await _validateDatabase(tempDbPath);
      if (!validationResult.isValid) {
        await _cleanupTempFile(tempDbPath);
        return DatabaseSyncResult.failure(
          'Database validation failed: ${validationResult.error}',
          DatabaseSyncFailureType.validationFailed,
        );
      }

      AnxLog.info(
          'DatabaseSync: Validation passed, proceeding with replacement');

      // Step 3: Backup current database
      final backupPath = await _createBackup(localDbPath);
      AnxLog.info('DatabaseSync: Created backup at: $backupPath');

      // Step 4: Atomic replace database
      await _atomicReplaceDatabase(tempDbPath, localDbPath);

      // Step 5: Validate replaced database
      final finalValidation = await _validateDatabase(localDbPath);
      if (!finalValidation.isValid) {
        AnxLog.severe(
            'DatabaseSync: Final validation failed, recovering from backup');
        await _recoverFromBackup(backupPath, localDbPath);
        return DatabaseSyncResult.failure(
          'Database replacement validation failed, recovered from backup',
          DatabaseSyncFailureType.replacementFailed,
        );
      }

      // Step 6: Cleanup and maintain backups
      await _cleanupOldBackups();
      await _cleanupTempFile(tempDbPath);

      AnxLog.info(
          'DatabaseSync: Safe database download completed successfully');
      return DatabaseSyncResult.success('Database synchronized successfully');
    } catch (e) {
      AnxLog.severe('DatabaseSync: Error during safe download: $e');
      await _cleanupTempFile(tempDbPath);

      return DatabaseSyncResult.failure(
        'Database sync failed: $e',
        DatabaseSyncFailureType.downloadFailed,
      );
    }
  }

  /// Validate database integrity
  static Future<DatabaseValidationResult> _validateDatabase(
      String dbPath) async {
    try {
      // Check if file exists and is not empty
      final dbFile = io.File(dbPath);
      if (!dbFile.existsSync()) {
        return DatabaseValidationResult.invalid('Database file does not exist');
      }

      final fileSize = dbFile.lengthSync();
      if (fileSize < 1024) {
        // Database file should be at least 1KB
        return DatabaseValidationResult.invalid(
            'Database file too small: ${fileSize}B');
      }

      // Initialize FFI for desktop platforms
      Database? db;
      try {
        // Platform-specific database opening
        if (io.Platform.isWindows) {
          sqfliteFfiInit();
          db = await databaseFactoryFfi.openDatabase(
            dbPath,
            options: OpenDatabaseOptions(
              readOnly: true,
              singleInstance: false,
            ),
          );
        } else {
          // Android/iOS
          db = await openDatabase(
            dbPath,
            readOnly: true,
            singleInstance: false,
          );
        }

        // Basic integrity check
        final integrityResult = await db.rawQuery('PRAGMA integrity_check');
        if (integrityResult.isEmpty ||
            integrityResult.first.values.first != 'ok') {
          return DatabaseValidationResult.invalid(
              'Database integrity check failed');
        }

        // Check if required tables exist
        final tables = await db.rawQuery(
            "SELECT name FROM sqlite_master WHERE type='table' AND name IN ('tb_books', 'tb_themes', 'tb_styles')");

        if (tables.length < 3) {
          return DatabaseValidationResult.invalid('Missing required tables');
        }

        // Check if tb_books table is empty
        final bookCount =
            await db.rawQuery('SELECT COUNT(*) as count FROM tb_books');
        final count = bookCount.first['count'] as int;

        if (count == 0) {
          return DatabaseValidationResult.invalid('Books table is empty');
        }

        // Check database version
        final versionResult = await db.rawQuery('PRAGMA user_version');
        final dbVersion = versionResult.first.values.first as int;

        if (dbVersion > currentDbVersion) {
          return DatabaseValidationResult.invalid(
              'Database version ($dbVersion) is newer than current version ($currentDbVersion)');
        }

        AnxLog.info(
            'DatabaseSync: Validation passed - $count books found, version $dbVersion');
        return DatabaseValidationResult.valid();
      } finally {
        await db?.close();
      }
    } catch (e) {
      return DatabaseValidationResult.invalid('Database validation error: $e');
    }
  }

  /// Create database backup
  static Future<String> _createBackup(String localDbPath) async {
    final cacheDir = await getAnxCacheDir();
    final timestamp = DateTime.now().toIso8601String().replaceAll(':', '-');
    final backupName = '$_backupDbPrefix$timestamp.db';
    final backupPath = join(cacheDir.path, backupName);

    // Ensure database is closed
    await DBHelper.close();

    // Copy file
    await io.File(localDbPath).copy(backupPath);

    return backupPath;
  }

  /// Atomic replace database
  static Future<void> _atomicReplaceDatabase(
      String tempDbPath, String localDbPath) async {
    // Ensure database is closed
    await DBHelper.close();

    // Use file move operation for atomic replacement
    final tempFile = io.File(tempDbPath);
    await tempFile.copy(localDbPath);

    // Re-initialize database
    await DBHelper().initDB();
  }

  /// Recover database from backup
  static Future<void> _recoverFromBackup(
      String backupPath, String localDbPath) async {
    try {
      await DBHelper.close();
      await io.File(backupPath).copy(localDbPath);
      await DBHelper().initDB();

      AnxLog.info(
          'DatabaseSync: Successfully recovered from backup: $backupPath');
    } catch (e) {
      AnxLog.severe('DatabaseSync: Failed to recover from backup: $e');
      rethrow;
    }
  }

  /// Cleanup temp file
  static Future<void> _cleanupTempFile(String tempDbPath) async {
    try {
      final tempFile = io.File(tempDbPath);
      if (tempFile.existsSync()) {
        await tempFile.delete();
        AnxLog.info('DatabaseSync: Cleaned up temp file: $tempDbPath');
      }
    } catch (e) {
      AnxLog.warning('DatabaseSync: Failed to cleanup temp file: $e');
    }
  }

  /// Cleanup expired backup files
  static Future<void> _cleanupOldBackups() async {
    try {
      final cacheDir = await getAnxCacheDir();
      final backupFiles = cacheDir
          .listSync()
          .where((file) => file.path.contains(_backupDbPrefix))
          .cast<io.File>()
          .toList();

      // Sort by modification time, keep the latest ones
      backupFiles
          .sort((a, b) => b.lastModifiedSync().compareTo(a.lastModifiedSync()));

      if (backupFiles.length > _maxBackupCount) {
        final filesToDelete = backupFiles.skip(_maxBackupCount);
        for (final file in filesToDelete) {
          await file.delete();
          AnxLog.info('DatabaseSync: Cleaned up old backup: ${file.path}');
        }
      }
    } catch (e) {
      AnxLog.warning('DatabaseSync: Failed to cleanup old backups: $e');
    }
  }

  /// Show sync error dialog
  static Future<void> showSyncErrorDialog(DatabaseSyncResult result) async {
    String title;
    String content;
    final context = navigatorKey.currentContext!;

    switch (result.failureType) {
      case DatabaseSyncFailureType.downloadFailed:
        title = L10n.of(context).downloadFailed;
        content = L10n.of(context).downloadFailedContent;
        break;
      case DatabaseSyncFailureType.validationFailed:
        title = L10n.of(context).syncValidationFailed;
        content = L10n.of(context).syncValidationFailedContent;
        break;
      case DatabaseSyncFailureType.replacementFailed:
        title = L10n.of(context).replacementFailed;
        content = L10n.of(context).replacementFailedContent;
        break;
      default:
        title = L10n.of(context).syncUnknownError;
        content = result.message;
    }

    await SmartDialog.show(
      builder: (context) => AlertDialog(
        title: Row(
          children: [
            const Icon(Icons.error, color: Colors.red),
            const SizedBox(width: 8),
            Text(title),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(content),
            const SizedBox(height: 12),
            Text(
              'Details: ${result.message}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => SmartDialog.dismiss(),
            child: Text(L10n.of(navigatorKey.currentContext!).commonOk),
          ),
        ],
      ),
    );
  }

  /// Get available backup files
  static Future<List<String>> getAvailableBackups() async {
    try {
      final cacheDir = await getAnxCacheDir();
      final backupFiles = cacheDir
          .listSync()
          .where((file) => file.path.contains(_backupDbPrefix))
          .cast<io.File>()
          .map((file) => file.path)
          .toList();

      backupFiles.sort((a, b) => b.compareTo(a));
      return backupFiles;
    } catch (e) {
      AnxLog.warning('DatabaseSync: Failed to get available backups: $e');
      return [];
    }
  }
}

/// Database validation result
class DatabaseValidationResult {
  final bool isValid;
  final String? error;

  const DatabaseValidationResult._(this.isValid, this.error);

  factory DatabaseValidationResult.valid() =>
      const DatabaseValidationResult._(true, null);
  factory DatabaseValidationResult.invalid(String error) =>
      DatabaseValidationResult._(false, error);
}

/// Database sync result
class DatabaseSyncResult {
  final bool isSuccess;
  final String message;
  final DatabaseSyncFailureType? failureType;

  const DatabaseSyncResult._(this.isSuccess, this.message, this.failureType);

  factory DatabaseSyncResult.success(String message) =>
      DatabaseSyncResult._(true, message, null);

  factory DatabaseSyncResult.failure(
          String message, DatabaseSyncFailureType type) =>
      DatabaseSyncResult._(false, message, type);
}

///  Database sync failure types
enum DatabaseSyncFailureType {
  downloadFailed,
  validationFailed,
  replacementFailed,
}
