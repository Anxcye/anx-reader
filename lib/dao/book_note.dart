import 'package:anx_reader/models/book_note.dart';

import 'database.dart';

Future<int> insertBookNote(BookNote bookNote) async {
  final db = await DBHelper().database;
  return db.insert('tb_notes', bookNote.toMap());
}

Future<List<BookNote>> selectBookNotesByBookId(int bookId) async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query('tb_notes', where: 'book_id = ?', whereArgs: [bookId]);
  return List.generate(maps.length, (i) {
    return BookNote(
      id: maps[i]['id'],
      bookId: maps[i]['book_id'],
      content: maps[i]['content'],
      cfi: maps[i]['cfi'],
      chapter: maps[i]['chapter'],
      type: maps[i]['type'],
      color: maps[i]['color'],
      createTime: DateTime.parse(maps[i]['create_time']),
      updateTime: DateTime.parse(maps[i]['update_time']),
    );
  });
}

void updateBookNoteById(BookNote bookNote) async {
  final db = await DBHelper().database;
  await db.update(
    'tb_notes',
    bookNote.toMap(),
    where: 'id = ?',
    whereArgs: [bookNote.id],
  );
}
Future<BookNote> selectBookNoteById(int id) async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query('tb_notes', where: 'id = ?', whereArgs: [id]);
  return BookNote(
    id: maps[0]['id'],
    bookId: maps[0]['book_id'],
    content: maps[0]['content'],
    cfi: maps[0]['cfi'],
    chapter: maps[0]['chapter'],
    type: maps[0]['type'],
    color: maps[0]['color'],
    createTime: DateTime.parse(maps[0]['create_time']),
    updateTime: DateTime.parse(maps[0]['update_time']),
  );
}