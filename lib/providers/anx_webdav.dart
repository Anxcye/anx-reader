import 'dart:async';
import 'dart:io' as io;
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/sync_state_model.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/sync_status.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webdav/safe_read.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:path/path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:webdav_client/webdav_client.dart';

part 'anx_webdav.g.dart';

@Riverpod(keepAlive: true)
class AnxWebdav extends _$AnxWebdav {
  static final AnxWebdav _instance = AnxWebdav._internal();

  factory AnxWebdav() {
    return _instance;
  }

  AnxWebdav._internal();

  @override
  SyncStateModel build() {
    return const SyncStateModel(
      direction: SyncDirection.both,
      isSyncing: false,
      total: 0,
      count: 0,
      fileName: '',
    );
  }

  void changeState(SyncStateModel s) {
    state = s;
  }

  static late Client _client;

  Future<void> init() async {
    _client = newClient(
      Prefs().webdavInfo['url'],
      user: Prefs().webdavInfo['username'],
      password: Prefs().webdavInfo['password'],
      debug: false,
    );
    _client.setHeaders({
      'accept-charset': 'utf-8',
      'Content-Type': 'application/octet-stream'
    });
    _client.setConnectTimeout(8000);

    try {
      await _client.ping();
    } catch (e) {
      AnxToast.show('WebDAV connection failed\n${e.toString()}',
          duration: 5000);
      AnxLog.severe('WebDAV connection failed, ping failed\n${e.toString()}');
      return;
    }

    await createAnxDir();
  }

  Future<void> createAnxDir() async {
    List<File> files = await _client.readDir('/');
    for (var element in files) {
      if (element.name == 'anx') {
        return;
      }
    }
    await _client.mkdir('anx');
    await _client.mkdir('anx/data');
  }

  Future<void> syncData(SyncDirection direction, WidgetRef? ref) async {
    if (Prefs().onlySyncWhenWifi &&
        !(await Connectivity().checkConnectivity())
            .contains(ConnectivityResult.wifi)) {
      if (Prefs().syncCompletedToast) {
        AnxToast.show(L10n.of(navigatorKey.currentContext!).webdav_only_wifi);
      }
      return;
    }

    if (!Prefs().webdavStatus) {
      return;
    }

    // test ping
    try {
      await _client.ping();
    } catch (e) {
      AnxLog.severe('WebDAV connection failed, ping failed2\n${e.toString()}');
      return;
    }

    AnxLog.info('WebDAV ping success');
    // if is syncing
    if (state.isSyncing) {
      return;
    }

    File? remoteDb = await safeReadProps('anx/app_database.db', _client);
    final databasePath = await getAnxDataBasesPath();
    final path = join(databasePath, 'app_database.db');
    io.File localDb = io.File(path);

    AnxLog.info(
        'localDbTime: ${localDb.lastModifiedSync()}, remoteDbTime: ${remoteDb?.mTime}');

    // less than 5s return
    if (remoteDb != null &&
        localDb.lastModifiedSync().difference(remoteDb.mTime!).inSeconds.abs() <
            5) {
      return;
    }
    
    if (remoteDb == null) {
      direction = SyncDirection.upload;
    }

    if (direction == SyncDirection.both) {
      if (Prefs().lastUploadBookDate == null ||
          Prefs()
                  .lastUploadBookDate!
                  .difference(remoteDb!.mTime!)
                  .inSeconds
                  .abs() >
              5) {
        SyncDirection? newDirection = await showDialog<SyncDirection>(
          context: navigatorKey.currentContext!,
          builder: (context) => AlertDialog(
            title: Text(L10n.of(context).common_attention),
            content: Text(L10n.of(context).webdav_sync_direction),
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
        if (newDirection != null) {
          direction = newDirection;
        } else {
          return;
        }
      }
    }

    changeState(state.copyWith(isSyncing: true));

    if (Prefs().syncCompletedToast) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!).webdav_syncing);
    }

    await backUpDb();

    try {
      await createAnxDir();

      await syncDatabase(direction);

      File? newRemoteDb = await safeReadProps('anx/app_database.db', _client);

      Prefs().lastUploadBookDate = newRemoteDb!.mTime;

      if (await isCurrentEmpty()) {
        await recoverDb();
        await _showSyncAbortedDialog();
        return;
      }

      if (Prefs().syncCompletedToast) {
        AnxToast.show(
            L10n.of(navigatorKey.currentContext!).webdav_syncing_files);
      }

      await syncFiles();

      imageCache.clear();
      imageCache.clearLiveImages();

      try {
        ref?.read(bookListProvider.notifier).refresh();
      } catch (e) {
        AnxLog.info('Failed to refresh book list: $e');
      }

      await deleteBackUpDb();

      ref?.read(syncStatusProvider.notifier).refresh();

      if (Prefs().syncCompletedToast) {
        AnxToast.show(
            L10n.of(navigatorKey.currentContext!).webdav_sync_complete);
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        AnxToast.show('WebDAV connection failed, check your network');
        AnxLog.severe('WebDAV connection failed, connection error\n$e');
      } else {
        AnxToast.show('Sync failed');
        AnxLog.severe('Sync failed\n$e');
      }
    } finally {
      changeState(state.copyWith(isSyncing: false));
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

  Future<void> syncFiles() async {
    List<String> currentBooks = await getCurrentBooks();
    List<String> currentCover = await getCurrentCover();
    List<File> remoteFiles = await _client.readDir('/anx/data');
    List<String> remoteBooksName = [];
    List<String> remoteCoversName = [];

    for (var file in remoteFiles) {
      if (file.name == 'file') {
        final remoteBooks = await _client.readDir('/anx/data/file');
        remoteBooksName = List.generate(
            remoteBooks.length, (index) => 'file/${remoteBooks[index].name!}');
      } else if (file.name == 'cover') {
        final remoteCovers = await _client.readDir('/anx/data/cover');
        remoteCoversName = List.generate(remoteCovers.length,
            (index) => 'cover/${remoteCovers[index].name!}');
      }
    }
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

    // abort if totalCurrentFiles is none
    if (totalCurrentFiles.isEmpty) {
      await _showSyncAbortedDialog();
      return;
    }

    // sync files
    for (var file in totalCurrentFiles) {
      if (!totalRemoteFiles.contains(file) && totalLocalFiles.contains(file)) {
        await uploadFile(getBasePath(file), 'anx/data/$file');
      }
      if (!io.File(getBasePath(file)).existsSync() &&
          totalRemoteFiles.contains(file)) {
        await downloadFile('anx/data/$file', getBasePath(file));
      }
    }
    // remove remote files not in database
    for (var file in totalRemoteFiles) {
      if (!totalCurrentFiles.contains(file)) {
        await _client.remove('anx/data/$file');
      }
    }
    // remove local files not in database
    for (var file in totalLocalFiles) {
      if (!totalCurrentFiles.contains(file)) {
        await io.File(getBasePath(file)).delete();
      }
    }
  }

  Future<void> syncDatabase(SyncDirection direction) async {
    File? remoteDb = await safeReadProps('anx/app_database.db', _client);

    final databasePath = await getAnxDataBasesPath();
    final path = join(databasePath, 'app_database.db');

    // backup local database
    await backUpDb();

    io.File localDb = io.File(path);

    try {
      switch (direction) {
        case SyncDirection.upload:
          DBHelper.close();
          await uploadFile(path, 'anx/app_database.db');
          await DBHelper().initDB();
          break;
        case SyncDirection.download:
          if (remoteDb != null) {
            DBHelper.close();
            await downloadFile('anx/app_database.db', path);
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
            await uploadFile(path, 'anx/app_database.db');
            await DBHelper().initDB();
          } else if (remoteDb.mTime!.isAfter(localDb.lastModifiedSync())) {
            DBHelper.close();
            await downloadFile('anx/app_database.db', path);
            await DBHelper().initDB();
          }
          break;
      }
    } catch (e) {
      await recoverDb();
      AnxLog.severe('Failed to sync database\n$e');
      rethrow;
    }
  }

  Future<void> uploadFile(
    String localPath,
    String remotePath, [
    bool replace = false,
  ]) async {
    CancelToken c = CancelToken();
    changeState(state.copyWith(direction: SyncDirection.upload));
    changeState(state.copyWith(fileName: localPath.split('/').last));
    if (replace) {
      try {
        await _client.remove(remotePath);
      } catch (e) {
        AnxLog.severe('Failed to remove file\n$e');
      }
    }
    await _client.writeFromFile(localPath, remotePath, onProgress: (c, t) {
      changeState(state.copyWith(isSyncing: true));
      changeState(state.copyWith(count: c));
      changeState(state.copyWith(total: t));
    }, cancelToken: c);

    // for (int i = 0; i <= 100; i++) {
    //   changeState(state.copyWith(isSyncing: true));
    //   changeState(state.copyWith(total: 100));
    //   changeState(state.copyWith(count: i));
    //   await Future.delayed(Duration(milliseconds: 50));
    // }
  }

  Future<void> downloadFile(String remotePath, String localPath) async {
    changeState(state.copyWith(direction: SyncDirection.download));
    changeState(state.copyWith(fileName: localPath.split('/').last));
    await _client.read2File(remotePath, localPath, onProgress: (c, t) {
      changeState(state.copyWith(isSyncing: true));
      changeState(state.copyWith(count: c));
      changeState(state.copyWith(total: t));
    });

    // for (int i = 0; i <= 100; i++) {
    //   changeState(state.copyWith(isSyncing: true));
    //   changeState(state.copyWith(total: 100));
    //   changeState(state.copyWith(count: i));
    //   await Future.delayed(Duration(milliseconds: 50));
    // }
  }

  Future<bool> isCurrentEmpty() async {
    List<String> currentBooks = await getCurrentBooks();
    List<String> currentCover = await getCurrentCover();
    List<String> totalCurrentFiles = [...currentCover, ...currentBooks];

    return totalCurrentFiles.isEmpty;
  }

  Future<void> backUpDb() async {
    final databasePath = await getAnxDataBasesPath();
    final path = join(databasePath, 'app_database.db');
    String cachePath = (await getAnxTempDir()).path;
    io.File(path).copySync('$cachePath/app_database.db');
  }

  Future<void> recoverDb() async {
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

  Future<List<String>> listRemoteBookFiles() async {
    final remoteFiles = await _client.readDir('/anx/data/file');
    return remoteFiles.map((e) => e.name!).toList();
  }
}
