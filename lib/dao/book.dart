import 'dart:convert';

import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/models/EpubPosition.dart';
import 'package:anx_reader/models/book.dart';

Future<int> insertBook(Book book) async {
  final db = await DBHelper().database;
  return db.insert('tb_books', book.toMap());
}

Future<List<Book>> selectBooks() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query('tb_books', orderBy: 'update_time DESC');
  return List.generate(maps.length, (i) {
    return Book(
      id: maps[i]['id'],
      title: maps[i]['title'],
      coverPath: maps[i]['cover_path'],
      filePath: maps[i]['file_path'],
      lastReadPosition: maps[i]['last_read_position'],
      author: maps[i]['author'],
      description: maps[i]['description'],
      createTime: DateTime.parse(maps[i]['create_time']),
      updateTime: DateTime.parse(maps[i]['update_time']),
    );
  });
}

Future<void> updateBook(Book book) async {
  book.updateTime = DateTime.now();
  final db = await DBHelper().database;
  print('update book: ${book.toMap()}');
  await db.update(
    'tb_books',
    book.toMap(),
    where: 'id = ?',
    whereArgs: [book.id],
  );
}