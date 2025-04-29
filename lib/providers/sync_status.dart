import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/sync_status.dart';
import 'package:anx_reader/providers/anx_webdav.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'sync_status.g.dart';

@Riverpod(keepAlive: true)
class SyncStatus extends _$SyncStatus {
  @override
  Future<SyncStatusModel> build() async {
    final allBooksInBookShelf = await _listAllBooksInBookShelf();
    final remoteFiles = await _listRemoteFiles(allBooksInBookShelf);
    final localFiles = await _listLocalFiles(allBooksInBookShelf);

    final localOnly = localFiles.where((e) => !remoteFiles.contains(e)).toList();
    final remoteOnly = remoteFiles.where((e) => !localFiles.contains(e)).toList();
    final both = localFiles.where((e) => remoteFiles.contains(e)).toList();
    final nonExistent = remoteFiles.where((e) => !localFiles.contains(e)).toList();
    List<int> downloading = [];
    List<int> uploading = [];

    return SyncStatusModel(
      localOnly: localOnly,
      remoteOnly: remoteOnly,
      both: both,
      nonExistent: nonExistent,
      downloading: downloading,
      uploading: uploading,
    );
  }

  Future<List<int>> _listRemoteFiles(List<Book> books) async {
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

  Future<List<int>> _listLocalFiles(List<Book> books) async {
    final localFiles =
        (await getFileDir().list().toList()).map((e) => e.path).toList();

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
