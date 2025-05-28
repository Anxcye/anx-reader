import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/models/bookmark.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

part 'bookmark.g.dart';

@Riverpod(keepAlive: true)
class BookmarkProvider extends _$BookmarkProvider {
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
        percentage: maps[i]['color']?.toDouble() ?? 0.0,
        chapter: maps[i]['chapter'],
        createTime: DateTime.parse(maps[i]['create_time']),
        updateTime: DateTime.parse(maps[i]['update_time']),
      );
    });
  }

  Future<void> addBookmark(BookmarkModel bookmark) async {
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
      var newState = [
        ...state.valueOrNull ?? [],
        bookmark,
      ];

      newState.sort((a, b) => a.percentage.compareTo(b.percentage));
      state = AsyncData(newState);
    }
  }

  void removeBookmark(BookmarkModel bookmark) {
    final db = DBHelper().database;
    db.then((database) {
      database.delete(
        'tb_notes',
        where: 'id = ?',
        whereArgs: [bookmark.id],
      );
    });

    var newState =
        state.valueOrNull?.where((b) => b.id != bookmark.id).toList() ?? [];
    state = AsyncData(newState);
  }
}
