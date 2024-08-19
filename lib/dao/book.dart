import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/utils/log/common.dart';

Future<int> insertBook(Book book) async {
  if (book.id != -1) {
    updateBook(book);
    return book.id;
  }
  final db = await DBHelper().database;
  return db.insert('tb_books', book.toMap());
}

Future<List<Book>> selectBooks() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps =
      await db.query('tb_books', orderBy: 'update_time DESC');
  return List.generate(maps.length, (i) {
    return Book(
      id: maps[i]['id'],
      title: maps[i]['title'],
      coverPath: maps[i]['cover_path'],
      filePath: maps[i]['file_path'],
      lastReadPosition: maps[i]['last_read_position'],
      readingPercentage: maps[i]['reading_percentage'],
      author: maps[i]['author'],
      isDeleted: maps[i]['is_deleted'] == 1 ? true : false,
      description: maps[i]['description'],
      rating: maps[i]['rating'] ?? 0.0,
      createTime: DateTime.parse(maps[i]['create_time']),
      updateTime: DateTime.parse(maps[i]['update_time']),
    );
  });
}

Future<List<Book>> selectNotDeleteBooks() {
  return selectBooks().then((books) {
    return books.where((book) => !book.isDeleted).toList();
  });
}

Future<void> updateBook(Book book) async {
  book.updateTime = DateTime.now();
  final db = await DBHelper().database;
  AnxLog.info('dao: update book: ${book.toMap()}');
  await db.update(
    'tb_books',
    book.toMap(),
    where: 'id = ?',
    whereArgs: [book.id],
  );
}

Future<Book> selectBookById(int id) async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query(
    'tb_books',
    where: 'id = ?',
    whereArgs: [id],
  );
  return Book(
    id: maps[0]['id'],
    title: maps[0]['title'],
    coverPath: maps[0]['cover_path'],
    filePath: maps[0]['file_path'],
    lastReadPosition: maps[0]['last_read_position'],
    readingPercentage: maps[0]['reading_percentage'],
    author: maps[0]['author'],
    isDeleted: maps[0]['is_deleted'] == 1 ? true : false,
    description: maps[0]['description'],
    rating: maps[0]['rating'] ?? 0.0,
    createTime: DateTime.parse(maps[0]['create_time']),
    updateTime: DateTime.parse(maps[0]['update_time']),
  );
}

Future<List<String>> getCurrentBooks() async {
  final books = await selectNotDeleteBooks();
  return books.map((book) => book.filePath).toList();
}

Future<List<String>> getCurrentCover() async {
  final books = await selectNotDeleteBooks();
  return books.map((book) => book.coverPath).toList();
}
