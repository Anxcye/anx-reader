import 'dart:async';
import 'dart:io' as io;
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/sync_state_model.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/sync_status.dart';
import 'package:anx_reader/providers/tb_groups.dart';
import 'package:anx_reader/service/sync/sync_processor.dart';
import 'package:anx_reader/service/sync/sync_client_factory.dart';
import 'package:anx_reader/service/sync/sync_client_base.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:webdav_client/webdav_client.dart';

part 'sync.g.dart';

@Riverpod(keepAlive: true)
class Sync extends _$Sync {
  static final Sync _instance = Sync._internal();

  factory Sync() {
    return _instance;
  }

  Sync._internal();

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

  static SyncProcessor? _syncProcessorInstance;

  SyncClientBase? get _syncClient {
    return SyncClientFactory.currentClient;
  }

  SyncProcessor? get _syncProcessor {
    return _syncProcessorInstance ??= SyncProcessor(
      onProgress: (fileName, direction, count, total) {
        changeState(state.copyWith(
          direction: direction,
          fileName: fileName,
          isSyncing: count < total,
          count: count,
          total: total,
        ));
      },
    );
  }

  Future<void> init() async {
    final processor = _syncProcessor;
    if (processor == null) {
      AnxLog.severe('No sync client configured');
      return;
    }
    
    try {
      await processor.initializeSync();
    } catch (e) {
      AnxLog.severe('Sync connection failed, ping failed\n${e.toString()}');
      return;
    }
  }

  Future<void> createAnxDir() async {
    // This method is now handled inside SyncProcessor.initializeSync()
    final processor = _syncProcessor;
    if (processor != null) {
      await processor.initializeSync();
    }
  }

  Future<void> syncData(SyncDirection direction, WidgetRef? ref) async {
    final processor = _syncProcessor;
    if (processor == null) {
      AnxLog.severe('No sync client configured');
      return;
    }

    if (!(await processor.shouldSync())) {
      return;
    }

    // Test ping and initialize
    try {
      await processor.initializeSync();
    } catch (e) {
      AnxLog.severe('Sync connection failed, ping failed2\n${e.toString()}');
      return;
    }

    AnxLog.info('Sync ping success');

    // Check if already syncing
    if (state.isSyncing) {
      return;
    }

    // Determine sync direction
    SyncDirection? finalDirection =
        await processor.determineSyncDirection(direction);
    if (finalDirection == null) {
      return; // User cancelled or no sync needed
    }

    changeState(state.copyWith(isSyncing: true));

    if (Prefs().syncCompletedToast) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!).webdav_syncing);
    }

    try {
      await processor.syncDatabase(finalDirection);

      if (await processor.isCurrentEmpty()) {
        await processor.deleteBackUpDb();
        changeState(state.copyWith(isSyncing: false));
        return;
      }

      if (Prefs().syncCompletedToast) {
        AnxToast.show(
            L10n.of(navigatorKey.currentContext!).webdav_syncing_files);
      }

      await processor.syncFiles();

      imageCache.clear();
      imageCache.clearLiveImages();

      try {
        ref?.read(bookListProvider.notifier).refresh();
        ref?.read(groupDaoProvider.notifier).refresh();
      } catch (e) {
        AnxLog.info('Failed to refresh book list: $e');
      }

      await processor.deleteBackUpDb();

      if (Prefs().syncCompletedToast) {
        AnxToast.show(
            L10n.of(navigatorKey.currentContext!).webdav_sync_complete);
      }
    } catch (e) {
      if (e is DioException && e.type == DioExceptionType.connectionError) {
        AnxToast.show('Sync connection failed, check your network');
        AnxLog.severe('Sync connection failed, connection error\n$e');
      } else {
        AnxToast.show('Sync failed\n$e');
        AnxLog.severe('Sync failed\n$e');
      }
    } finally {
      changeState(state.copyWith(isSyncing: false));
    }
  }

  Future<void> syncFiles() async {
    final processor = _syncProcessor;
    if (processor != null) {
      await processor.syncFiles();
    }
  }

  Future<void> syncDatabase(SyncDirection direction) async {
    final processor = _syncProcessor;
    if (processor != null) {
      await processor.syncDatabase(direction);
    }
  }

  String safeEncodePath(String path) {
    // This method is now private in WebdavClient
    return Uri.encodeComponent(path).replaceAll('%2F', '/');
  }

  Future<void> uploadFile(
    String localPath,
    String remotePath, [
    bool replace = true,
  ]) async {
    changeState(state.copyWith(
      direction: SyncDirection.upload,
      fileName: localPath.split('/').last,
    ));

    final client = _syncClient;
    if (client != null) {
      await client.uploadFile(
        localPath,
        remotePath,
        replace: replace,
        onProgress: (sent, total) {
          changeState(state.copyWith(
            isSyncing: true,
            count: sent,
            total: total,
          ));
        },
      );
    }

    changeState(state.copyWith(isSyncing: false));
  }

  Future<void> downloadFile(String remotePath, String localPath) async {
    changeState(state.copyWith(
      direction: SyncDirection.download,
      fileName: remotePath.split('/').last,
    ));

    final client = _syncClient;
    if (client != null) {
      await client.downloadFile(
        remotePath,
        localPath,
        onProgress: (received, total) {
          changeState(state.copyWith(
            isSyncing: true,
            count: received,
            total: total,
          ));
        },
      );
    }

    changeState(state.copyWith(isSyncing: false));
  }

  Future<List<File>> safeReadDir(String path) async {
    final client = _syncClient;
    if (client != null) {
      return await client.safeReadDir(path);
    }
    return [];
  }

  Future<bool> isCurrentEmpty() async {
    final processor = _syncProcessor;
    return processor != null ? await processor.isCurrentEmpty() : true;
  }

  Future<void> backUpDb() async {
    final processor = _syncProcessor;
    if (processor != null) {
      await processor.deleteBackUpDb(); // Using the same backup method
    }
  }

  Future<void> recoverDb() async {
    // This is now handled internally by SyncProcessor
  }

  Future<void> deleteBackUpDb() async {
    final processor = _syncProcessor;
    if (processor != null) {
      await processor.deleteBackUpDb();
    }
  }

  Future<List<String>> listRemoteBookFiles() async {
    final processor = _syncProcessor;
    return processor != null ? await processor.listRemoteBookFiles() : [];
  }

  Future<void> downloadBook(Book book) async {
    final syncStatus = await ref.read(syncStatusProvider.future);

    if (!syncStatus.remoteOnly.contains(book.id)) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .book_sync_status_book_not_found_remote);
      return;
    }

    try {
      final processor = _syncProcessor;
      if (processor != null) {
        await processor.downloadBook(book);
      }
    } catch (e) {
      // Error handling is done in SyncProcessor
    }
  }

  Future<void> uploadBook(Book book) async {
    final syncStatus = await ref.read(syncStatusProvider.future);

    Future<void> deleteLocalBook() async {
      await io.File(getBasePath(book.filePath)).delete();
    }

    Future<void> uploadBook() async {
      final processor = _syncProcessor;
      if (processor != null) {
        await processor.uploadBook(book);
      }
    }

    if (syncStatus.remoteOnly.contains(book.id)) {
      AnxToast.show(L10n.of(navigatorKey.currentContext!)
          .book_sync_status_space_released);
      return;
    } else if (syncStatus.both.contains(book.id)) {
      await deleteLocalBook();
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
        final book = await selectBookById(bookId);
        AnxLog.info('WebDAV: Downloading book ID $bookId: ${book.title}');
        final processor = _syncProcessor;
        if (processor != null) {
          await processor.downloadBook(book);
        }
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
}
