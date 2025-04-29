import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/sync_status.dart';
import 'package:anx_reader/providers/anx_webdav.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_status.g.dart';

@Riverpod(keepAlive: true)
class SyncStatus extends _$SyncStatus {
  @override
  Future<SyncStatusModel> build() async {
    print('build');
    final allBooksInBookShelf = await _listAllBooksInBookShelf();
    final allBooksInBookShelfIds =
        allBooksInBookShelf.map((e) => e.id).toList();
    final remoteFiles = await _listRemoteFiles(allBooksInBookShelf);
    final localFiles = await _listLocalFiles(allBooksInBookShelf);

    final localOnly =
        localFiles.where((e) => !remoteFiles.contains(e)).toList();
    final remoteOnly =
        remoteFiles.where((e) => !localFiles.contains(e)).toList();
    final both = localFiles.where((e) => remoteFiles.contains(e)).toList();
    final nonExistent = allBooksInBookShelfIds
        .where((e) => !localFiles.contains(e) && !remoteFiles.contains(e))
        .toList();
    final webdavInfo = ref.read(anxWebdavProvider);

    final isSyncing =
        ref.watch(anxWebdavProvider.select((value) => value.isSyncing));

    List<int> downloading =
        isSyncing && webdavInfo.direction == SyncDirection.download
            ? [
                allBooksInBookShelf
                    .firstWhere((e) => e.filePath.contains(webdavInfo.fileName))
                    .id
              ]
            : [];
    List<int> uploading =
        isSyncing && webdavInfo.direction == SyncDirection.upload
            ? [
                allBooksInBookShelf
                    .firstWhere((e) => e.filePath.contains(webdavInfo.fileName))
                    .id
              ]
            : [];
    return SyncStatusModel(
      localOnly: localOnly,
      remoteOnly: remoteOnly,
      both: both,
      nonExistent: nonExistent,
      downloading: downloading,
      uploading: uploading,
    );
  }

  Future<void> refresh() async {
    state = AsyncData(await build());
  }

  Future<List<int>> _listRemoteFiles(List<Book> books) async {
    Future<List<int>> core() async {
      final remoteFiles =
          await ref.read(anxWebdavProvider.notifier).listRemoteBookFiles();
      final remoteFilesIds = books
          .map((e) {
            final filePath = e.filePath.split('/').last;
            final isExist = remoteFiles.contains(filePath);
            return isExist ? e.id : null;
          })
          .whereType<int>()
          .toList();
      return remoteFilesIds;
    }

    int count = 0;
    const maxCount = 2;
    while (true) {
      try {
        return await core();
      } catch (e) {
        AnxLog.info(
            'Webdav: Failed to list remote files: $e try again $count/$maxCount');
        count++;
        if (count >= maxCount) {
          AnxLog.info('Webdav: Failed to list remote files: $e');
          return [];
        }
      }
    }
  }

  Future<List<int>> _listLocalFiles(List<Book> books) async {
    final localFiles = (await getFileDir().list().toList())
        .map((e) => e.path.split(Platform.pathSeparator).last)
        .toList();

    final localFilesIds = books
        .map((e) {
          final filePath = e.filePath.split('/').last;
          final isExist = localFiles.contains(filePath);
          return isExist ? e.id : null;
        })
        .whereType<int>()
        .toList();
    return localFilesIds;
  }

  Future<List<Book>> _listAllBooksInBookShelf() async {
    return await selectNotDeleteBooks();
  }
}
