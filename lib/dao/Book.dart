import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/models/Book.dart';

Future<int> insertBook(Book book) async {
  final db = await DBHelper().database;
  print('db insert book');
  return db.insert('tb_books', book.toMap());
}

Future<List<Map<String, dynamic>>> getAllBooks() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query('tb_books');
  return maps;
}
