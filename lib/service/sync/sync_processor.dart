import 'dart:io' as io;
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:path/path.dart';
import 'package:webdav_client/webdav_client.dart';

class SyncProcessor {
  final SyncClientBase _syncClient;
  final void Function(
          String fileName, SyncDirection direction, int count, int total)?
      onProgress;

  SyncProcessor({
    required SyncClientBase syncClient,
    this.onProgress,
  }) : _syncClient = syncClient;

  Future<void> initializeSync() async {
    try {
      await _syncClient.ping();
      await _createAnxDir();
    } catch (e) {
      AnxLog.severe('${_syncClient.protocolName} connection failed, ping failed\n${e.toString()}');
      rethrow;
    }
    AnxLog.info('${_syncClient.protocolName}: init');
  }

  Future<bool> shouldSync() async {
    if (!Prefs().webdavStatus) {
      return false;
    }

    if (Prefs().onlySyncWhenWifi &&
        !(await Connectivity().checkConnectivity())
            .contains(ConnectivityResult.wifi)) {
      if (Prefs().syncCompletedToast) {
        AnxToast.show(L10n.of(navigatorKey.currentContext!).webdav_only_wifi);
      }
      return false;
    }

    return true;
  }

  Future<void> _createAnxDir() async {
    try {
      await _syncClient.isExist('/anx/data/file');
    } catch (e) {
      await _syncClient.mkdir('anx');
      await _syncClient.mkdir('anx/data');
      await _syncClient.mkdir('anx/data/file');
      await _syncClient.mkdir('anx/data/cover');
    }
  }

  Future<SyncDirection?> determineSyncDirection(
      SyncDirection requestedDirection) async {
    String remoteDbFileName = 'database$currentDbVersion.db';

    // Check for version mismatch
    List<File> remoteFiles = [];
    try {
      remoteFiles = await _syncClient.safeReadDir('/anx');
    } catch (e) {
      await _createAnxDir();
      remoteFiles = await _syncClient.safeReadDir('/anx');
    }

    for (var file in remoteFiles) {
      if (file.name != null &&
          file.name!.startsWith('database') &&
          file.name!.endsWith('.db')) {
        String versionStr =
            file.name!.replaceAll('database', '').replaceAll('.db', '');
        int version = int.tryParse(versionStr) ?? 0;
        if (version > currentDbVersion) {
          await _showDatabaseVersionMismatchDialog(version);
          return null;
        }
      }
    }

    // File? remoteDb = await safeReadProps('anx/$remoteDbFileName', _syncClient);
    File? remoteDb = await _syncClient.readProps('anx/$remoteDbFileName');
    final databasePath = await getAnxDataBasesPath();
    final localDbPath = join(databasePath, 'app_database.db');
    io.File localDb = io.File(localDbPath);

    AnxLog.info(
        'localDbTime: ${localDb.lastModifiedSync()}, remoteDbTime: ${remoteDb?.mTime}');

    // Less than 5s difference, no sync needed
    if (remoteDb != null &&
        localDb.lastModifiedSync().difference(remoteDb.mTime!).inSeconds.abs() <
            5) {
      return null;
    }

    if (remoteDb == null) {
      return SyncDirection.upload;
    }

    if (requestedDirection == SyncDirection.both) {
      if (Prefs().lastUploadBookDate == null ||
          Prefs()
                  .lastUploadBookDate!
                  .difference(remoteDb.mTime!)
                  .inSeconds
                  .abs() >
              5) {
        return await _showSyncDirectionDialog(localDb, remoteDb);
      }
    }

    return requestedDirection;
  }

  Future<SyncDirection?> _showSyncDirectionDialog(
      io.File localDb, File remoteDb) async {
    return await showDialog<SyncDirection>(
      context: navigatorKey.currentContext!,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).common_attention),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(L10n.of(context).webdav_sync_direction),
            SizedBox(height: 10),
            Text(
                '${L10n.of(context).book_sync_status_local_update_time} ${localDb.lastModifiedSync()}'),
            Text(
                '${L10n.of(context).sync_remote_data_update_time} ${remoteDb.mTime}'),
          ],
        ),
        actionsOverflowDirection: VerticalDirection.up,
        actionsOverflowAlignment: OverflowBarAlignment.center,
        actionsOverflowButtonSpacing: 10,
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop(SyncDirection.upload);
            },
            child: Text(L10n.of(context).webdav_upload),
          ),
          FilledButton(
            onPressed: () {
              Navigator.of(context).pop(SyncDirection.download);
            },
            child: Text(L10n.of(context).webdav_download),
          ),
        ],
      ),
    );
  }

  Future<void> syncDatabase(SyncDirection direction) async {
    String remoteDbFileName = 'database$currentDbVersion.db';
    File? remoteDb = await _syncClient.readProps('anx/$remoteDbFileName');
    final databasePath = await getAnxDataBasesPath();
    final localDbPath = join(databasePath, 'app_database.db');
    io.File localDb = io.File(localDbPath);

    // Backup local database
    await _backUpDb();

    try {
      switch (direction) {
        case SyncDirection.upload:
          DBHelper.close();
          await _uploadFile(localDbPath, 'anx/$remoteDbFileName');
          await DBHelper().initDB();
          break;
        case SyncDirection.download:
          if (remoteDb != null) {
            DBHelper.close();
            await _downloadFile('anx/$remoteDbFileName', localDbPath);
            await DBHelper().initDB();
          } else {
            await _showSyncAbortedDialog();
            return;
          }
          break;
        case SyncDirection.both:
          if (remoteDb == null ||
              remoteDb.mTime!.isBefore(localDb.lastModifiedSync())) {
            DBHelper.close();
            await _uploadFile(localDbPath, 'anx/$remoteDbFileName');
            await DBHelper().initDB();
          } else if (remoteDb.mTime!.isAfter(localDb.lastModifiedSync())) {
            DBHelper.close();
            await _downloadFile('anx/$remoteDbFileName', localDbPath);
            await DBHelper().initDB();
          }
          break;
      }

      // Update last sync time
      File? newRemoteDb =
          await _syncClient.readProps('anx/$remoteDbFileName');
      if (newRemoteDb != null) {
        Prefs().lastUploadBookDate = newRemoteDb.mTime;
      }
    } catch (e) {
      await _recoverDb();
      AnxLog.severe('Failed to sync database\n$e');
      rethrow;
    }
  }

  Future<void> syncFiles() async {
    List<String> currentBooks = await getCurrentBooks();
    List<String> currentCover = await getCurrentCover();

    List<String> remoteBooksName = [];
    List<String> remoteCoversName = [];

    List<File> remoteBooks = await _syncClient.safeReadDir('/anx/data/file');
    remoteBooksName = List.generate(
        remoteBooks.length, (index) => 'file/${remoteBooks[index].name!}');

    List<File> remoteCovers =
        await _syncClient.safeReadDir('/anx/data/cover');
    remoteCoversName = List.generate(
        remoteCovers.length, (index) => 'cover/${remoteCovers[index].name!}');

    List<String> totalCurrentFiles = [...currentCover, ...currentBooks];
    List<String> totalRemoteFiles = [...remoteBooksName, ...remoteCoversName];

    List<String> localBooks =
        io.Directory(getBasePath('file')).listSync().map((e) {
      return 'file/${basename(e.path)}';
    }).toList();
    List<String> localCovers =
        io.Directory(getBasePath('cover')).listSync().map((e) {
      return 'cover/${basename(e.path)}';
    }).toList();
    List<String> totalLocalFiles = [...localBooks, ...localCovers];

    // Abort if totalCurrentFiles is empty
    if (totalCurrentFiles.isEmpty) {
      await _showSyncAbortedDialog();
      return;
    }

    // Sync cover files
    for (var file in currentCover) {
      if (!remoteCoversName.contains(file) && localCovers.contains(file)) {
        await _uploadFile(getBasePath(file), 'anx/data/$file');
      }
      if (!io.File(getBasePath(file)).existsSync() &&
          remoteCoversName.contains(file)) {
        await _downloadFile('anx/data/$file', getBasePath(file));
      }
    }

    // Sync book files
    for (var file in currentBooks) {
      if (!remoteBooksName.contains(file) && localBooks.contains(file)) {
        await _uploadFile(getBasePath(file), 'anx/data/$file');
      }
    }

    // Remove remote files not in database
    for (var file in totalRemoteFiles) {
      if (!totalCurrentFiles.contains(file)) {
        await _syncClient.remove('anx/data/$file');
      }
    }

    // Remove local files not in database
    for (var file in totalLocalFiles) {
      if (!totalCurrentFiles.contains(file)) {
        await io.File(getBasePath(file)).delete();
      }
    }
  }

  Future<void> _uploadFile(String localPath, String remotePath) async {
    String fileName = localPath.split('/').last;
    onProgress?.call(fileName, SyncDirection.upload, 0, 0);

    await _syncClient.uploadFile(
      localPath,
      remotePath,
      onProgress: (sent, total) {
        onProgress?.call(fileName, SyncDirection.upload, sent, total);
      },
    );
  }

  Future<void> _downloadFile(String remotePath, String localPath) async {
    String fileName = remotePath.split('/').last;
    onProgress?.call(fileName, SyncDirection.download, 0, 0);

    await _syncClient.downloadFile(
      remotePath,
      localPath,
      onProgress: (received, total) {
        onProgress?.call(fileName, SyncDirection.download, received, total);
      },
    );
  }

  Future<void> downloadBook(Book book) async {
    try {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .book_sync_status_downloading_book(book.filePath));
      final remotePath = 'anx/data/${book.filePath}';
      final localPath = getBasePath(book.filePath);
      await _downloadFile(remotePath, localPath);
    } catch (e) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .book_sync_status_download_failed);
      AnxLog.severe('Failed to download book\n$e');
      rethrow;
    }
  }

  Future<void> uploadBook(Book book) async {
    try {
      final remotePath = 'anx/data/${book.filePath}';
      final localPath = getBasePath(book.filePath);
      await _uploadFile(localPath, remotePath);
    } catch (e) {
      AnxToast.show(
          L10n.of(navigatorKey.currentContext!).book_sync_status_upload_failed);
      AnxLog.severe('Failed to upload book\n$e');
      rethrow;
    }
  }

  Future<List<String>> listRemoteBookFiles() async {
    final remoteFiles = await _syncClient.safeReadDir('/anx/data/file');
    return remoteFiles.map((e) => e.name!).toList();
  }

  Future<bool> isCurrentEmpty() async {
    List<String> currentBooks = await getCurrentBooks();
    List<String> currentCover = await getCurrentCover();
    List<String> totalCurrentFiles = [...currentCover, ...currentBooks];
    return totalCurrentFiles.isEmpty;
  }

  Future<void> _backUpDb() async {
    final databasePath = await getAnxDataBasesPath();
    final path = join(databasePath, 'app_database.db');
    String cachePath = (await getAnxTempDir()).path;
    io.File(path).copySync('$cachePath/app_database.db');
  }

  Future<void> _recoverDb() async {
    AnxLog.info('WebDAV: recoverDb');
    final databasePath = await getAnxDataBasesPath();
    final path = join(databasePath, 'app_database.db');
    String cachePath = (await getAnxTempDir()).path;

    DBHelper.close();
    io.File('$cachePath/app_database.db').copySync(path);
    await DBHelper().initDB();
  }

  Future<void> deleteBackUpDb() async {
    String cachePath = (await getAnxTempDir()).path;
    if (io.File('$cachePath/app_database.db').existsSync()) {
      io.File('$cachePath/app_database.db').deleteSync();
    }
  }

  Future<void> _showSyncAbortedDialog() async {
    await SmartDialog.show(
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).webdav_sync_aborted),
        content: Text(L10n.of(context).webdav_sync_aborted_content),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(L10n.of(context).common_ok),
          ),
        ],
      ),
    );
  }

  Future<void> _showDatabaseVersionMismatchDialog(int remoteVersion) async {
    await SmartDialog.show(
      clickMaskDismiss: false,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).webdav_sync_aborted),
        content: Text(L10n.of(context)
            .sync_mismatch_tip(currentDbVersion, remoteVersion)),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(L10n.of(context).common_ok),
          ),
        ],
      ),
    );
  }
}
