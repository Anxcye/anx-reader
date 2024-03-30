import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/models/book.dart';

Future<int> insertBook(Book book) async {
  final db = await DBHelper().database;
  return db.insert('tb_books', book.toMap());
}

Future<List<Book>> getAllBooks() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query('tb_books');
  return List.generate(maps.length, (i) {
    return Book(
      id: maps[i]['id'],
      title: maps[i]['title'],
      coverPath: maps[i]['cover_path'],
      filePath: maps[i]['file_path'],
      lastReadPosition: maps[i]['last_read_position'],
      author: maps[i]['author'],
      description: maps[i]['description'],
    );
  });
}
