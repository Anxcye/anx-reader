import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/models/bookmark.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

part 'bookmark.g.dart';

@Riverpod(keepAlive: true)
class Bookmark extends _$Bookmark {
  @override
  Future<List<BookmarkModel>> build(int bookId) async {
    final db = await DBHelper().database;
    final List<Map<String, dynamic>> maps = await db.query('tb_notes',
        where: 'type = ? AND book_id = ?', whereArgs: ['bookmark', bookId]);

    return List.generate(maps.length, (i) {
      return BookmarkModel(
        id: maps[i]['id'],
        bookId: maps[i]['book_id'],
        content: maps[i]['content'],
        cfi: maps[i]['cfi'],
        percentage: double.tryParse(maps[i]['color']) ?? 0.0,
        chapter: maps[i]['chapter'],
        createTime: DateTime.parse(maps[i]['create_time']),
        updateTime: DateTime.parse(maps[i]['update_time']),
      );
    });
  }

  void refreshBookmarks() {
    ref.invalidateSelf();
  }

  Future<BookmarkModel> addBookmark(BookmarkModel bookmark) async {
    final db = await DBHelper().database;

    final List<Map<String, dynamic>> maps = await db.query('tb_notes',
        where: 'cfi = ? AND book_id = ?', whereArgs: [bookmark.cfi, bookId]);
    if (maps.isEmpty) {
      int id = await db.insert(
        'tb_notes',
        bookmark.toMap(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

      bookmark = bookmark.copyWith(id: id);
      List<BookmarkModel> newState = [
        ...state.valueOrNull ?? [],
        bookmark,
      ];

      newState.sort((a, b) => a.percentage.compareTo(b.percentage));
      state = AsyncData(newState);
    }

    return bookmark;
  }

  void removeBookmark({int? id, String? cfi}) {
    assert(id != null || cfi != null, 'Either id or cfi must be provided');
    assert(!(id != null && cfi != null),
        'Only one of id or cfi should be provided');

    try {
      if (id == null) {
        final bookmark = state.valueOrNull?.firstWhere((b) => b.cfi == cfi);
        id = bookmark?.id;
      }

      if (cfi == null) {
        final bookmark = state.valueOrNull?.firstWhere((b) => b.id == id);
        cfi = bookmark?.cfi;
      }

      final db = DBHelper().database;
      db.then((database) {
        database.delete(
          'tb_notes',
          where: 'id = ?',
          whereArgs: [id],
        );
      });

      var newState = state.valueOrNull?.where((b) => b.id != id).toList() ?? [];
      state = AsyncData(newState);
      final key = epubPlayerKey.currentState;
      key?.removeAnnotation(cfi!);
    } catch (e) {
      AnxLog.info('Bookmark already removed: $e');
    }
  }
}
