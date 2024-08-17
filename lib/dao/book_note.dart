
import 'package:anx_reader/models/book_note.dart';

import 'database.dart';

Future<int> insertBookNote(BookNote bookNote) async {
  if (bookNote.id != null) {
    updateBookNoteById(bookNote);
    return bookNote.id!;
  }

  List<BookNote> bookNotes = await selectBookNoteByCfiAndBookId(bookNote.cfi, bookNote.bookId);
  if (bookNotes.isNotEmpty) {
    bookNote.id = bookNotes.last.id;
    updateBookNoteById(bookNote);
    return bookNote.id!;
  }

  final db = await DBHelper().database;
  return db.insert('tb_notes', bookNote.toMap());
}

Future<List<BookNote>> selectBookNoteByCfiAndBookId(String cfi, int bookId) async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query('tb_notes', where: 'cfi = ? AND book_id = ?', whereArgs: [cfi, bookId]);
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

Future<List<BookNote>> selectBookNotesByBookId(int bookId) async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps =
      await db.query('tb_notes', where: 'book_id = ?', whereArgs: [bookId]);
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
  final List<Map<String, dynamic>> maps =
      await db.query('tb_notes', where: 'id = ?', whereArgs: [id]);
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

Future<List<Map<String, int>>> selectAllBookIdAndNotes() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT book_id, COUNT(id) AS number_of_notes FROM tb_notes GROUP BY book_id ORDER BY number_of_notes DESC');
  return List.generate(maps.length, (i) {
    return {
      'bookId': maps[i]['book_id'],
      'numberOfNotes': maps[i]['number_of_notes'],
    };
  });
}

Future<Map<String, int>> selectNumberOfNotesAndBooks() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT COUNT(id) AS number_of_notes, COUNT(DISTINCT book_id) AS number_of_books FROM tb_notes');
  return {
    'numberOfNotes': maps[0]['number_of_notes'],
    'numberOfBooks': maps[0]['number_of_books'],
  };
}

void deleteBookNoteById(int id) async {
  final db = await DBHelper().database;
  await db.delete(
    'tb_notes',
    where: 'id = ?',
    whereArgs: [id],
  );
}
