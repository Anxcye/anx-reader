import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../page/epub_player.dart';
import '../utils/import_book.dart';

Future<Book> importBook(File file) async {
  EpubBookRef epubBookRef = await EpubReader.openBook(file.readAsBytesSync());
  String author = epubBookRef.Author ?? 'Unknown Author';
  String title = epubBookRef.Title ?? 'Unknown';
  final cover = await epubBookRef.readCover();
  final newBookName = '$title - $author - ${DateTime.now().toString()}';

  Directory appDocDir = await getApplicationDocumentsDirectory();
  final fileDir = Directory('${appDocDir.path}/file');
  final coverDir = Directory('${appDocDir.path}/cover');
  if (!fileDir.existsSync()) {
    fileDir.createSync();
  }
  if (!coverDir.existsSync()) {
    coverDir.createSync();
  }
  final filePath = '${fileDir.path}/$newBookName.epub';
  final coverPath = '${coverDir.path}/$newBookName.png';

  await file.copy(filePath);
  saveImageToLocal(cover, coverPath);

  Book book = Book(
      id: -1,
      title: title,
      coverPath: coverPath,
      filePath: filePath,
      lastReadPosition: '',
      author: author,
      createTime: DateTime.now(),
      updateTime: DateTime.now());
  book.id = await insertBook(book);
  return book;
}

void openBook(BuildContext context, Book book, Function updateBookList) {
  book.updateTime = DateTime.now();
  updateBook(book);
  Future.delayed(Duration(seconds: 1), () {
    updateBookList();
  });

  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (context) => EpubPlayer(book: book),
    ),
  ).then((cfi) {
    if (cfi != null) {
      book.lastReadPosition = cfi;
      print(cfi);
      updateBook(book);
      // updateBookList();
    }
  });
  print('Open book: ${book.title}');
}
