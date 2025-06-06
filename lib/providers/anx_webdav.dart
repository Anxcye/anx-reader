import 'dart:async';
import 'dart:io' as io;
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/sync_state_model.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/sync_status.dart';
import 'package:anx_reader/providers/tb_groups.dart';
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

  static Client? clientInstance;

  Client get _client {
    return clientInstance ??= newClient(
      Prefs().webdavInfo['url'],
      user: Prefs().webdavInfo['username'],
      password: Prefs().webdavInfo['password'],
      debug: false,
    )
      ..setHeaders({
        'accept-charset': 'utf-8',
        'Content-Type': 'application/octet-stream'
      })
      ..setConnectTimeout(
        8000,
      );
  }

  Future<void> init() async {
    try {
      await _client.ping();
    } catch (e) {
      AnxLog.severe('WebDAV connection failed, ping failed\n${e.toString()}');
      return;
    }
    AnxLog.info('WebDAV: init');
  }

  Future<void> createAnxDir() async {
    try {
      await _client.read('/anx/data/file');
    } catch (e) {
      await _client.mkdir('anx');
      await _client.mkdir('anx/data');
      await _client.mkdir('anx/data/file');
      await _client.mkdir('anx/data/cover');
    }
  }

  Future<void> syncData(SyncDirection direction, WidgetRef? ref) async {
    if (!Prefs().webdavStatus) {
      return;
    }

    if (Prefs().onlySyncWhenWifi &&
        !(await Connectivity().checkConnectivity())
            .contains(ConnectivityResult.wifi)) {
      if (Prefs().syncCompletedToast) {
        AnxToast.show(L10n.of(navigatorKey.currentContext!).webdav_only_wifi);
      }
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

    await createAnxDir();

    // Check for remote database files with version info
    String remoteDbFileName = 'database$currentDbVersion.db';

    try {
      List<File> remoteFiles = [];
      try {
        remoteFiles = await safeReadDir('/anx');
      } catch (e) {
        await createAnxDir();
        remoteFiles = await safeReadDir('/anx');
      }
      for (var file in remoteFiles) {
        if (file.name != null &&
            file.name!.startsWith('database') &&
            file.name!.endsWith('.db')) {
          // Extract version number
          String versionStr =
              file.name!.replaceAll('database', '').replaceAll('.db', '');
          int version = int.tryParse(versionStr) ?? 0;
          if (version > currentDbVersion) {
            await _showDatabaseVersionMismatchDialog(version);
            return;
          }
        }
      }
    } catch (e) {
      AnxLog.severe('WebDAV: Error checking database versions: $e');
    }

    File? remoteDb = await safeReadProps('anx/$remoteDbFileName', _client);
    final databasePath = await getAnxDataBasesPath();
    final localDbPath = join(databasePath, 'app_database.db');
    io.File localDb = io.File(localDbPath);

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
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(L10n.of(context).webdav_sync_direction),
                SizedBox(height: 10),
                Text('${L10n.of(context).book_sync_status_local_update_time} ${localDb.lastModifiedSync()}'),
                Text('${L10n.of(context).sync_remote_data_update_time} ${remoteDb!.mTime}'),
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
      await syncDatabase(direction);

      File? newRemoteDb = await safeReadProps('anx/$remoteDbFileName', _client);

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
        ref?.read(groupDaoProvider.notifier).refresh();
      } catch (e) {
        AnxLog.info('Failed to refresh book list: $e');
      }

      await deleteBackUpDb();

      if (Prefs().syncCompletedToast) {
        AnxToast.show(
            L10n.of(navigatorKey.currentContext!).webdav_sync_complete);
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        AnxToast.show('WebDAV connection failed, check your network');
        AnxLog.severe('WebDAV connection failed, connection error\n$e');
      } else {
        AnxToast.show('Sync failed\n$e');
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
    // List<File> remoteFiles = await _client.readDir('/anx/data');
    List<String> remoteBooksName = [];
    List<String> remoteCoversName = [];

    List<File> remoteBooks = [];
    List<File> remoteCovers = [];

    remoteBooks = await safeReadDir('/anx/data/file');

    remoteBooksName = List.generate(
        remoteBooks.length, (index) => 'file/${remoteBooks[index].name!}');

    remoteCovers = await safeReadDir('/anx/data/cover');

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

    // abort if totalCurrentFiles is none
    if (totalCurrentFiles.isEmpty) {
      await _showSyncAbortedDialog();
      return;
    }
    // cover files
    for (var file in currentCover) {
      if (!remoteCoversName.contains(file) && localCovers.contains(file)) {
        await uploadFile(getBasePath(file), 'anx/data/$file');
      }
      if (!io.File(getBasePath(file)).existsSync() &&
          remoteCoversName.contains(file)) {
        await downloadFile('anx/data/$file', getBasePath(file));
      }
    }

    // book files
    for (var file in currentBooks) {
      if (!remoteBooksName.contains(file) && localBooks.contains(file)) {
        await uploadFile(getBasePath(file), 'anx/data/$file');
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
    String remoteDbFileName = 'database$currentDbVersion.db';
    File? remoteDb = await safeReadProps('anx/$remoteDbFileName', _client);

    final databasePath = await getAnxDataBasesPath();
    final localDbPath = join(databasePath, 'app_database.db');

    // backup local database
    await backUpDb();

    io.File localDb = io.File(localDbPath);

    try {
      switch (direction) {
        case SyncDirection.upload:
          DBHelper.close();
          await uploadFile(localDbPath, 'anx/$remoteDbFileName');
          await DBHelper().initDB();
          break;
        case SyncDirection.download:
          if (remoteDb != null) {
            DBHelper.close();
            await downloadFile('anx/$remoteDbFileName', localDbPath);
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
            await uploadFile(localDbPath, 'anx/$remoteDbFileName');
            await DBHelper().initDB();
          } else if (remoteDb.mTime!.isAfter(localDb.lastModifiedSync())) {
            DBHelper.close();
            await downloadFile('anx/$remoteDbFileName', localDbPath);
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

  String safeEncodePath(String path) {
    return Uri.encodeComponent(path).replaceAll('%2F', '/');
  }

  Future<void> uploadFile(
    String localPath,
    String remotePath, [
    bool replace = true,
  ]) async {
    CancelToken c = CancelToken();
    changeState(state.copyWith(
      direction: SyncDirection.upload,
      fileName: localPath.split('/').last,
    ));
    if (replace) {
      try {
        await _client.remove(safeEncodePath(remotePath));
      } catch (e) {
        AnxLog.severe('Failed to remove file\n$e');
      }
    }
    await _client.writeFromFile(localPath, safeEncodePath(remotePath),
        onProgress: (c, t) {
      changeState(state.copyWith(
        isSyncing: true,
        count: c,
        total: t,
      ));
    }, cancelToken: c);

    changeState(state.copyWith(isSyncing: false));

    // for (int i = 0; i <= 100; i++) {
    //   changeState(state.copyWith(isSyncing: true));
    //   changeState(state.copyWith(total: 100));
    //   changeState(state.copyWith(count: i));
    //   await Future.delayed(Duration(milliseconds: 50));
    // }
  }

  Future<void> downloadFile(String remotePath, String localPath) async {
    changeState(state.copyWith(
      direction: SyncDirection.download,
      fileName: remotePath.split('/').last,
    ));
    await _client.read2File(safeEncodePath(remotePath), localPath,
        onProgress: (c, t) {
      changeState(state.copyWith(
        isSyncing: true,
        count: c,
        total: t,
      ));
    });

    changeState(state.copyWith(isSyncing: false));

    // for (int i = 0; i <= 100; i++) {
    //   changeState(state.copyWith(isSyncing: true));
    //   changeState(state.copyWith(total: 100));
    //   changeState(state.copyWith(count: i));
    //   await Future.delayed(Duration(milliseconds: 50));
    // }
  }

  Future<List<File>> safeReadDir(String path) async {
    try {
      return await _client.readDir(path);
    } catch (e) {
      await _client.mkdir(path);
      return await _client.readDir(path);
    }
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

  Future<List<String>> listRemoteBookFiles() async {
    final remoteFiles = await safeReadDir('/anx/data/file');
    return remoteFiles.map((e) => e.name!).toList();
  }

  Future<void> downloadBook(Book book) async {
    final syncStatus = await ref.read(syncStatusProvider.future);

    if (!syncStatus.remoteOnly.contains(book.id)) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .book_sync_status_book_not_found_remote);
      return;
    }
    try {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .book_sync_status_downloading_book(book.filePath));
      final remotePath = 'anx/data/${book.filePath}';
      final localPath = getBasePath(book.filePath);
      downloadFile(remotePath, localPath);
    } catch (e) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .book_sync_status_download_failed);
      AnxLog.severe('Failed to download book\n$e');
    }
  }

  Future<void> uploadBook(Book book) async {
    final syncStatus = await ref.read(syncStatusProvider.future);

    Future<void> deleteLocalBook() async {
      await io.File(getBasePath(book.filePath)).delete();
    }

    Future<void> uploadBook() async {
      final remotePath = 'anx/data/${book.filePath}';
      final localPath = getBasePath(book.filePath);
      await uploadFile(localPath, remotePath);
    }

    if (syncStatus.remoteOnly.contains(book.id)) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .book_sync_status_space_released);
      return;
    } else if (syncStatus.both.contains(book.id)) {
      deleteLocalBook();
    } else {
      try {
        await uploadBook();
        await deleteLocalBook();
      } catch (e) {
        AnxToast.show(L10n.of(navigatorKey.currentContext!)
            .book_sync_status_upload_failed);
      }
    }
  }

  Future<void> downloadMultipleBooks(List<int> bookIds) async {
    AnxLog.info(
        'WebDAV: Starting download for ${bookIds.length} remote books.');
    int successCount = 0;
    int failCount = 0;

    try {
      await _client.ping();
    } catch (e) {
      AnxLog.severe(
          'WebDAV connection failed before batch download, ping failed\n${e.toString()}');
      return;
    }

    for (final bookId in bookIds) {
      try {
        final book = await selectBookById(bookId);
        AnxLog.info('WebDAV: Downloading book ID $bookId: ${book.title}');
        await downloadBook(book);
        successCount++;
      } catch (e) {
        AnxLog.severe('WebDAV: Failed to download book ID $bookId: $e');
        failCount++;
      }
    }

    AnxLog.info(L10n.of(navigatorKey.currentContext!)
        .webdavBatchDownloadFinishedReport(successCount, failCount));
    AnxToast.show(L10n.of(navigatorKey.currentContext!)
        .webdavBatchDownloadFinishedReport(successCount, failCount));
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
