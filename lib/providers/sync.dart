import 'dart:async';
import 'dart:io' as io;
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/remote_file.dart';
import 'package:anx_reader/models/sync_state_model.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/sync_status.dart';
import 'package:anx_reader/providers/tb_groups.dart';
import 'package:anx_reader/service/sync/sync_client_factory.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/service/sync/reading_agent_sync_service.dart';
import 'package:anx_reader/service/sync/cloudbase_reading_sync_coordinator.dart';
import 'package:anx_reader/service/sync/sync_request_gate.dart';
import 'package:anx_reader/service/ai/reading_device_identity.dart';
import 'package:anx_reader/service/database_sync_manager.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/utils/get_path/databases_path.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:dio/dio.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';
import 'package:path/path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync.g.dart';

@Riverpod(keepAlive: true)
class Sync extends _$Sync {
  static final Sync _instance = Sync._internal();
  static final SyncRequestGate<void> _syncGate = SyncRequestGate<void>();
  static const Duration _progressUpdateInterval = Duration(milliseconds: 100);
  static const Duration _automaticSyncCooldown = Duration(minutes: 3);
  static const Duration _offlineRetryBackoff = Duration(minutes: 5);

  DateTime? _lastProgressUpdate;
  DateTime? _lastAutomaticSyncAttempt;
  DateTime? _lastOfflineSyncCheck;

  factory Sync() {
    return _instance;
  }

  Sync._internal();

  // Flag to prevent multiple sync direction dialogs
  bool _isShowingDirectionDialog = false;

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

  void _reportProgress({
    required SyncDirection direction,
    required String fileName,
    required int count,
    required int total,
  }) {
    final now = DateTime.now();
    final completed = total > 0 && count >= total;
    if (!completed &&
        _lastProgressUpdate != null &&
        now.difference(_lastProgressUpdate!) < _progressUpdateInterval) {
      return;
    }
    _lastProgressUpdate = now;
    changeState(state.copyWith(
      direction: direction,
      fileName: fileName,
      isSyncing: true,
      count: count,
      total: total,
    ));
  }

  SyncClientBase? get _syncClient {
    if (SyncClientFactory.currentClient == null) {
      SyncClientFactory.initializeCurrentClient();
    }
    return SyncClientFactory.currentClient;
  }

  Future<void> init() async {
    final client = _syncClient;
    if (client == null) {
      AnxLog.severe('No sync client configured');
      return;
    }

    AnxLog.info('${client.protocolName}: init');
  }

  Future<void> _createAnxDir() async {
    final client = _syncClient;
    if (client == null) return;

    if (!await client.isExist('/anx/data/file')) {
      await client.mkdirAll('anx/data/file');
      await client.mkdirAll('anx/data/cover');
    }
  }

  Future<DateTime> _latestDatabaseModification(String dbPath) async {
    var latest = DateTime.fromMillisecondsSinceEpoch(0);
    for (final path in <String>[dbPath, '$dbPath-wal']) {
      final file = io.File(path);
      if (!await file.exists()) continue;
      final modified = await file.lastModified();
      if (modified.isAfter(latest)) latest = modified;
    }
    return latest;
  }

  Future<bool> shouldSync() async {
    if (!Prefs().webdavStatus) {
      return false;
    }

    if (Prefs().onlySyncWhenWifi &&
        !(await Connectivity().checkConnectivity())
            .contains(ConnectivityResult.wifi)) {
      if (Prefs().syncCompletedToast) {
        AnxToast.show(L10n.of(navigatorKey.currentContext!).webdavOnlyWifi);
      }
      return false;
    }

    return true;
  }

  Future<SyncDirection?> determineSyncDirection(
      SyncDirection requestedDirection,
      {SyncTrigger trigger = SyncTrigger.manual}) async {
    final client = _syncClient;
    if (client == null) return null;

    String remoteDbFileName = 'database$currentDbVersion.db';

    // Check for version mismatch
    List<RemoteFile> remoteFiles = [];
    try {
      remoteFiles = await client.safeReadDir('/anx');
    } catch (e) {
      await _createAnxDir();
      remoteFiles = await client.safeReadDir('/anx');
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

    RemoteFile? remoteDb = await client.readProps('anx/$remoteDbFileName');
    final databasePath = await getAnxDataBasesPath();
    final localDbPath = join(databasePath, 'app_database.db');
    // Include WAL modification time without synchronous filesystem calls on
    // the UI isolate.
    final localDbTime = await _latestDatabaseModification(localDbPath);
    AnxLog.info('localDbTime: $localDbTime, remoteDbTime: ${remoteDb?.mTime}');

    // Less than 5s difference, no sync needed
    if (remoteDb != null &&
        localDbTime.difference(remoteDb.mTime!).inSeconds.abs() < 5) {
      return null;
    }

    if (remoteDb == null) {
      return SyncDirection.upload;
    }

    if (requestedDirection == SyncDirection.both &&
        trigger == SyncTrigger.auto) {
      // Automatic checks must never open a blocking direction dialog. Treat a
      // remote timestamp equal to the last successful upload as our own write.
      final knownRemote = Prefs().lastUploadBookDate;
      final knownLocal = Prefs().lastSyncLocalDatabaseTime;
      final localChanged =
          knownLocal == null || localDbTime.isAfter(knownLocal);
      final remoteChanged = knownRemote == null ||
          remoteDb.mTime == null ||
          remoteDb.mTime!.difference(knownRemote).inSeconds.abs() >= 5;

      if (!remoteChanged && !localChanged) return null;
      if (localChanged && !remoteChanged) {
        // Local reading edits are silently uploaded during automatic sync.
        return SyncDirection.upload;
      }
      if (!localChanged && remoteChanged) {
        // A remote-only change can be safely downloaded without asking.
        return SyncDirection.download;
      }

      // Both sides changed. Defer the conflict to an explicit manual sync;
      // never interrupt an active reading session with a modal dialog.
      AnxLog.info('WebDAV conflict deferred during automatic sync');
      return null;
    }

    if (requestedDirection == SyncDirection.both) {
      if (Prefs().lastUploadBookDate == null ||
          Prefs()
                  .lastUploadBookDate!
                  .difference(remoteDb.mTime!)
                  .inSeconds
                  .abs() >
              5) {
        return await _showSyncDirectionDialog(localDbTime, remoteDb);
      }
    }

    return requestedDirection;
  }

  Future<SyncDirection?> _showSyncDirectionDialog(
      DateTime localDbTime, RemoteFile remoteDb) async {
    // Prevent multiple dialogs from showing simultaneously
    if (_isShowingDirectionDialog) {
      AnxLog.info('Sync direction dialog already showing, skipping');
      return null;
    }

    _isShowingDirectionDialog = true;
    try {
      return await showDialog<SyncDirection>(
        context: navigatorKey.currentContext!,
        barrierDismissible: false, // Prevent dismissing by tapping outside
        builder: (context) => AlertDialog(
          title: Text(L10n.of(context).commonAttention),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(L10n.of(context).webdavSyncDirection),
              SizedBox(height: 10),
              Text(
                  '${L10n.of(context).bookSyncStatusLocalUpdateTime} $localDbTime'),
              Text(
                  '${L10n.of(context).syncRemoteDataUpdateTime} ${remoteDb.mTime}'),
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
              child: Text(L10n.of(context).webdavUpload),
            ),
            FilledButton(
              onPressed: () {
                Navigator.of(context).pop(SyncDirection.download);
              },
              child: Text(L10n.of(context).webdavDownload),
            ),
          ],
        ),
      );
    } finally {
      _isShowingDirectionDialog = false;
    }
  }

  Future<void> _showDatabaseVersionMismatchDialog(int remoteVersion) async {
    await SmartDialog.show(
      clickMaskDismiss: false,
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).webdavSyncAborted),
        content: Text(
            L10n.of(context).syncMismatchTip(currentDbVersion, remoteVersion)),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(L10n.of(context).commonOk),
          ),
        ],
      ),
    );
  }

  Future<void> syncData(
    SyncDirection direction,
    WidgetRef? ref, {
    SyncTrigger trigger = SyncTrigger.auto,
  }) {
    if (trigger == SyncTrigger.auto && !Prefs().autoSync) {
      return Future<void>.value();
    }

    final duplicate = _syncGate.isRunning;
    final result = _syncGate.run(() async {
      changeState(state.copyWith(
        direction: direction,
        isSyncing: true,
        total: 0,
        count: 0,
        fileName: '',
      ));
      _lastProgressUpdate = null;
      try {
        await _performSyncData(direction, ref, trigger: trigger);
      } finally {
        changeState(state.copyWith(isSyncing: false));
      }
    });
    if (duplicate) {
      AnxLog.info('Sync request joined the operation already in progress');
    }
    return result;
  }

  Future<void> _performSyncData(
    SyncDirection direction,
    WidgetRef? ref, {
    required SyncTrigger trigger,
  }) async {
    final silent = trigger == SyncTrigger.auto;
    if (silent) {
      final now = DateTime.now();
      final lastAttempt = _lastAutomaticSyncAttempt;
      if (lastAttempt != null &&
          now.difference(lastAttempt) < _automaticSyncCooldown) {
        AnxLog.info('Skipping automatic sync during cooldown');
        return;
      }
      final connectivity = await Connectivity().checkConnectivity();
      if (connectivity.contains(ConnectivityResult.none)) {
        final lastOfflineCheck = _lastOfflineSyncCheck;
        if (lastOfflineCheck != null &&
            now.difference(lastOfflineCheck) < _offlineRetryBackoff) {
          AnxLog.info('Skipping automatic sync while offline');
          return;
        }
        _lastOfflineSyncCheck = now;
        AnxLog.info('Deferring automatic sync while offline');
        return;
      }
      _lastAutomaticSyncAttempt = now;
    }

    if (Prefs().cloudBaseSyncEnabled) {
      try {
        final wifiAllowed = !Prefs().onlySyncWhenWifi ||
            (await Connectivity().checkConnectivity())
                .contains(ConnectivityResult.wifi);
        if (wifiAllowed) {
          await const CloudBaseReadingSyncCoordinator().synchronize();
        }
      } catch (error, stackTrace) {
        AnxLog.warning(
          'CloudBase Reading Sync failed: $error\n$stackTrace',
        );
        if (trigger == SyncTrigger.manual) {
          AnxToast.show('CloudBase 阅读同步失败：$error');
        }
      }
    }

    final client = _syncClient;
    if (!Prefs().webdavStatus || client == null) {
      return;
    }

    if (!(await shouldSync())) {
      return;
    }

    // Test ping and initialize
    try {
      await client.ping();
      await _createAnxDir();
    } catch (e) {
      AnxLog.severe('Sync connection failed, ping failed2\n${e.toString()}');
      return;
    }

    AnxLog.info('Sync ping success');

    // Determine sync direction
    SyncDirection? finalDirection = await determineSyncDirection(
      direction,
      trigger: trigger,
    );
    if (finalDirection == null) {
      return; // User cancelled or no sync needed
    }

    changeState(state.copyWith(isSyncing: true));

    if (!silent && Prefs().syncCompletedToast) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!).webdavSyncing);
    }

    try {
      final deviceId = await ReadingDeviceIdentity().getOrCreate();
      final readingAgentSync = ReadingAgentSyncService(deviceId: deviceId);
      // Capture before the legacy database sync: a remote database download
      // may replace the whole local database.
      final readingAgentBeforeDatabaseSync = await readingAgentSync.capture();
      await syncDatabase(finalDirection);

      if (await isCurrentEmpty()) {
        await _showSyncAbortedDialog();
        return;
      }

      await readingAgentSync.synchronize(
        client,
        localBeforeDatabaseSync: readingAgentBeforeDatabaseSync,
      );

      if (!silent && Prefs().syncCompletedToast) {
        AnxToast.show(L10n.of(navigatorKey.currentContext!).webdavSyncingFiles);
      }

      await syncFiles(ref);

      imageCache.clear();
      imageCache.clearLiveImages();

      try {
        ref?.read(bookListProvider.notifier).refresh();
        ref?.read(groupDaoProvider.notifier).refresh();
      } catch (e) {
        AnxLog.info('Failed to refresh book list: $e');
      }

      // Backup cleanup is now handled by DatabaseSyncManager

      if (!silent && Prefs().syncCompletedToast) {
        AnxToast.show(L10n.of(navigatorKey.currentContext!).webdavSyncComplete);
      }
    } catch (e, s) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        AnxToast.show('Sync connection failed, check your network');
        AnxLog.severe('Sync connection failed, connection error\n$e, $s');
      } else {
        AnxToast.show('Sync failed\n$e');
        AnxLog.severe('Sync failed\n$e, $s');
      }
    }
  }

  Future<void> syncFiles([WidgetRef? widgetRef]) async {
    final client = _syncClient;
    if (client == null) return;

    AnxLog.info('Sync: syncFiles');
    final currentBooks = (await bookDao.getCurrentBooks()).toSet();
    final currentCover = (await bookDao.getCurrentCover()).toSet();

    final remoteBooks = await client.safeReadDir('/anx/data/file');
    final remoteBooksName = remoteBooks
        .map((file) => file.name)
        .whereType<String>()
        .map((name) => 'file/$name')
        .toSet();

    final remoteCovers = await client.safeReadDir('/anx/data/cover');
    final remoteCoversName = remoteCovers
        .map((file) => file.name)
        .whereType<String>()
        .map((name) => 'cover/$name')
        .toSet();

    final totalCurrentFiles = {...currentCover, ...currentBooks};
    final totalRemoteFiles = {...remoteBooksName, ...remoteCoversName};

    final localBooks = await io.Directory(getBasePath('file'))
        .list()
        .map((entity) => 'file/${basename(entity.path)}')
        .toSet();
    final localCovers = await io.Directory(getBasePath('cover'))
        .list()
        .map((entity) => 'cover/${basename(entity.path)}')
        .toSet();
    final totalLocalFiles = {...localBooks, ...localCovers};

    // Abort if totalCurrentFiles is empty
    if (totalCurrentFiles.isEmpty) {
      await _showSyncAbortedDialog();
      return;
    }

    // Sync cover files
    for (var file in currentCover) {
      if (!remoteCoversName.contains(file) && localCovers.contains(file)) {
        await uploadFile(getBasePath(file), 'anx/data/$file');
      }
      if (!await io.File(getBasePath(file)).exists() &&
          remoteCoversName.contains(file)) {
        await downloadFile('anx/data/$file', getBasePath(file));
      }
    }

    // Sync book files
    for (var file in currentBooks) {
      if (!remoteBooksName.contains(file) && localBooks.contains(file)) {
        await uploadFile(getBasePath(file), 'anx/data/$file');
      }
    }

    // Remove remote files not in database
    for (var file in totalRemoteFiles) {
      if (!totalCurrentFiles.contains(file)) {
        await client.remove('anx/data/$file');
      }
    }

    // Remove local files not in database
    for (var file in totalLocalFiles) {
      if (!totalCurrentFiles.contains(file)) {
        await io.File(getBasePath(file)).delete();
      }
    }
    // Background callers do not necessarily own a mounted WidgetRef. A UI
    // refresh is optional and must not turn completed file work into failure.
    try {
      widgetRef?.read(syncStatusProvider.notifier).refresh();
    } catch (error) {
      AnxLog.info('Skipped sync status refresh: $error');
    }
  }

  Future<void> syncDatabase(SyncDirection direction) async {
    final client = _syncClient;
    if (client == null) return;

    String remoteDbFileName = 'database$currentDbVersion.db';
    RemoteFile? remoteDb = await client.readProps('anx/$remoteDbFileName');

    final databasePath = await getAnxDataBasesPath();
    final localDbPath = join(databasePath, 'app_database.db');
    final localDbTime = await _latestDatabaseModification(localDbPath);

    try {
      switch (direction) {
        case SyncDirection.upload:
          // Use VACUUM INTO to create a snapshot, avoiding database locking/closing
          final snapshotPath = await DBHelper.prepareUploadSnapshot();
          try {
            await uploadFile(snapshotPath, 'anx/$remoteDbFileName');
          } finally {
            // Clean up snapshot file
            final snapshotFile = io.File(snapshotPath);
            if (await snapshotFile.exists()) {
              await snapshotFile.delete();
            }
          }
          break;

        case SyncDirection.download:
          if (remoteDb != null) {
            // Use safe database download method
            final result = await DatabaseSyncManager.safeDownloadDatabase(
              client: client,
              remoteDbFileName: remoteDbFileName,
              onProgress: (received, total) {
                _reportProgress(
                  direction: SyncDirection.download,
                  fileName: remoteDbFileName,
                  count: received,
                  total: total,
                );
              },
            );

            if (!result.isSuccess) {
              await DatabaseSyncManager.showSyncErrorDialog(result);
              AnxLog.severe('Database sync failed: ${result.message}');
              // Don't throw exception, let sync continue with file sync
              return;
            }
          } else {
            await _showSyncAbortedDialog();
            return;
          }
          break;

        case SyncDirection.both:
          if (remoteDb == null || remoteDb.mTime!.isBefore(localDbTime)) {
            // Use VACUUM INTO to create a snapshot, avoiding database locking/closing
            final snapshotPath = await DBHelper.prepareUploadSnapshot();
            try {
              await uploadFile(snapshotPath, 'anx/$remoteDbFileName');
            } finally {
              // Clean up snapshot file
              final snapshotFile = io.File(snapshotPath);
              if (await snapshotFile.exists()) {
                await snapshotFile.delete();
              }
            }
          } else if (remoteDb.mTime!.isAfter(localDbTime)) {
            // Use safe database download method
            final result = await DatabaseSyncManager.safeDownloadDatabase(
              client: client,
              remoteDbFileName: remoteDbFileName,
              onProgress: (received, total) {
                _reportProgress(
                  direction: SyncDirection.download,
                  fileName: remoteDbFileName,
                  count: received,
                  total: total,
                );
              },
            );

            if (!result.isSuccess) {
              await DatabaseSyncManager.showSyncErrorDialog(result);
              AnxLog.severe('Database sync failed: ${result.message}');
              // Don't throw exception, let sync continue with file sync
              return;
            }
          }
          break;
      }

      // Update last sync time
      RemoteFile? newRemoteDb = await client.readProps('anx/$remoteDbFileName');
      if (newRemoteDb != null) {
        Prefs().lastUploadBookDate = newRemoteDb.mTime;
      }
      // Capture the post-sync local timestamp (including WAL) as the next
      // automatic comparison baseline.
      Prefs().lastSyncLocalDatabaseTime =
          await _latestDatabaseModification(localDbPath);
    } catch (e) {
      AnxLog.severe('Failed to sync database\n$e');
      rethrow;
    }
  }

  Future<void> uploadFile(
    String localPath,
    String remotePath, [
    bool replace = true,
  ]) async {
    final standalone = !_syncGate.isRunning;
    changeState(state.copyWith(
      direction: SyncDirection.upload,
      fileName: localPath.split('/').last,
      isSyncing: true,
      count: 0,
      total: 0,
    ));

    final client = _syncClient;
    if (client != null) {
      ref.read(syncStatusProvider.notifier).addUploading(remotePath);
      try {
        await client.uploadFile(
          localPath,
          remotePath,
          replace: replace,
          onProgress: (sent, total) {
            _reportProgress(
              direction: SyncDirection.upload,
              fileName: localPath.split('/').last,
              count: sent,
              total: total,
            );
          },
        );
      } finally {
        ref.read(syncStatusProvider.notifier).removeUploading(remotePath);
      }
    }

    if (standalone) changeState(state.copyWith(isSyncing: false));
  }

  Future<void> downloadFile(String remotePath, String localPath) async {
    final standalone = !_syncGate.isRunning;
    changeState(state.copyWith(
      direction: SyncDirection.download,
      fileName: remotePath.split('/').last,
      isSyncing: true,
      count: 0,
      total: 0,
    ));

    final client = _syncClient;
    if (client != null) {
      ref.read(syncStatusProvider.notifier).addDownloading(remotePath);
      try {
        await client.downloadFile(
          remotePath,
          localPath,
          onProgress: (received, total) {
            _reportProgress(
              direction: SyncDirection.download,
              fileName: remotePath.split('/').last,
              count: received,
              total: total,
            );
          },
        );
      } finally {
        ref.read(syncStatusProvider.notifier).removeDownloading(remotePath);
      }
    }

    if (standalone) changeState(state.copyWith(isSyncing: false));
  }

  Future<List<String>> listRemoteBookFiles() async {
    final client = _syncClient;
    if (client == null) return [];

    final remoteFiles = await client.safeReadDir('/anx/data/file');
    return remoteFiles.map((e) => e.name!).toList();
  }

  Future<void> downloadBook(Book book) async {
    final syncStatus = await ref.read(syncStatusProvider.future);

    if (!syncStatus.remoteOnly.contains(book.id)) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .bookSyncStatusBookNotFoundRemote);
      return;
    }

    try {
      await _downloadBook(book);
    } catch (e) {
      // Error handling is done in _downloadBook
    }
  }

  Future<void> releaseBook(Book book) async {
    final syncStatus = await ref.read(syncStatusProvider.future);

    Future<void> deleteLocalBook() async {
      await io.File(getBasePath(book.filePath)).delete();
    }

    Future<void> uploadBook() async {
      try {
        final remotePath = 'anx/data/${book.filePath}';
        final localPath = getBasePath(book.filePath);
        await uploadFile(localPath, remotePath);
      } catch (e) {
        AnxToast.show(
            L10n.of(navigatorKey.currentContext!).bookSyncStatusUploadFailed);
        AnxLog.severe('Failed to upload book\n$e');
        rethrow;
      }
    }

    if (syncStatus.remoteOnly.contains(book.id)) {
      AnxToast.show(
          L10n.of(navigatorKey.currentContext!).bookSyncStatusSpaceReleased);
      return;
    } else if (syncStatus.both.contains(book.id)) {
      await deleteLocalBook();
      ref.read(syncStatusProvider.notifier).refresh();
    } else {
      try {
        await uploadBook();
        await deleteLocalBook();
      } catch (e) {
        AnxToast.show(
            L10n.of(navigatorKey.currentContext!).bookSyncStatusUploadFailed);
      }
    }
  }

  Future<void> downloadMultipleBooks(List<int> bookIds) async {
    AnxLog.info(
        'WebDAV: Starting download for ${bookIds.length} remote books.');
    int successCount = 0;
    int failCount = 0;

    try {
      final client = _syncClient;
      if (client != null) {
        await client.ping();
      } else {
        throw Exception('No sync client configured');
      }
    } catch (e) {
      AnxLog.severe(
          'WebDAV connection failed before batch download, ping failed\n${e.toString()}');
      return;
    }

    for (final bookId in bookIds) {
      try {
        final book = await bookDao.selectBookById(bookId);
        AnxLog.info('WebDAV: Downloading book ID $bookId: ${book.title}');
        await _downloadBook(book);
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

  Future<void> _downloadBook(Book book) async {
    try {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .bookSyncStatusDownloadingBook(book.filePath));
      final remotePath = 'anx/data/${book.filePath}';
      final localPath = getBasePath(book.filePath);
      await downloadFile(remotePath, localPath);
    } catch (e) {
      AnxToast.show(
          L10n.of(navigatorKey.currentContext!).bookSyncStatusDownloadFailed);
      AnxLog.severe('Failed to download book\n$e');
      rethrow;
    }
  }

  Future<bool> isCurrentEmpty() async {
    List<String> currentBooks = await bookDao.getCurrentBooks();
    List<String> currentCover = await bookDao.getCurrentCover();
    List<String> totalCurrentFiles = [...currentCover, ...currentBooks];
    return totalCurrentFiles.isEmpty;
  }

  /// Get available database backup list
  Future<List<String>> getAvailableBackups() async {
    return await DatabaseSyncManager.getAvailableBackups();
  }

  /// Show database backup management dialog
  Future<void> showBackupManagementDialog() async {
    try {
      final backups = await getAvailableBackups();

      await SmartDialog.show(
        builder: (context) => AlertDialog(
          title: Text(L10n.of(context).databaseBackupManagement),
          content: SizedBox(
            width: double.maxFinite,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(L10n.of(context).availableBackups),
                const SizedBox(height: 12),
                if (backups.isEmpty)
                  Text(
                    L10n.of(context).noBackupsAvailable,
                    style: const TextStyle(color: Colors.grey),
                  )
                else
                  SizedBox(
                    height: 200,
                    child: ListView.builder(
                      itemCount: backups.length,
                      itemBuilder: (context, index) {
                        final backup = backups[index];
                        final fileName = backup.split('/').last;
                        final timestamp = fileName
                            .replaceAll('backup_database_', '')
                            .replaceAll('.db', '');

                        return ListTile(
                          title: Text('Backup ${index + 1}'),
                          subtitle: Text(timestamp),
                          trailing: ElevatedButton(
                            onPressed: () async {
                              // Navigator.of(context).pop();
                              await _restoreFromBackup(backup);
                            },
                            child: Text(L10n.of(context).restore),
                          ),
                        );
                      },
                    ),
                  ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text(L10n.of(context).commonCancel),
            ),
          ],
        ),
      );
    } catch (e) {
      AnxLog.severe('Failed to show backup management dialog: $e');
      AnxToast.show('Failed to get backup list: $e');
    }
  }

  /// Restore database from specified backup
  Future<void> _restoreFromBackup(String backupPath) async {
    try {
      final databasePath = await getAnxDataBasesPath();
      final localDbPath = join(databasePath, 'app_database.db');

      // Confirmation dialog
      final confirmed = await SmartDialog.show<bool>(
        builder: (context) => AlertDialog(
          title: Text(L10n.of(context).confirmRestore),
          content: Text(L10n.of(context).restoreWarning),
          actions: [
            TextButton(
              onPressed: () => SmartDialog.dismiss(result: false),
              child: Text(L10n.of(context).commonCancel),
            ),
            FilledButton(
              onPressed: () => SmartDialog.dismiss(result: true),
              child: Text(L10n.of(context).commonConfirm),
            ),
          ],
        ),
      );

      if (confirmed != true) return;

      // Execute restore
      await DBHelper.close();
      await io.File(backupPath).copy(localDbPath);
      await DBHelper().initDB();

      // Refresh related providers
      try {
        ref.read(bookListProvider.notifier).refresh();
        ref.read(groupDaoProvider.notifier).refresh();
      } catch (e) {
        AnxLog.info('Failed to refresh providers after restore: $e');
      }

      AnxToast.show(L10n.of(navigatorKey.currentContext!).restoreSuccess);
      AnxLog.info('Database restored from backup: $backupPath');
    } catch (e) {
      AnxLog.severe('Failed to restore from backup: $e');
      AnxToast.show('Restore failed: $e');
    }
  }

  Future<void> _showSyncAbortedDialog() async {
    await SmartDialog.show(
      builder: (context) => AlertDialog(
        title: Text(L10n.of(context).webdavSyncAborted),
        content: Text(L10n.of(context).webdavSyncAbortedContent),
        actions: [
          TextButton(
            onPressed: () {
              SmartDialog.dismiss();
            },
            child: Text(L10n.of(context).commonOk),
          ),
        ],
      ),
    );
  }
}
