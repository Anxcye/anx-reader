import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../page/reading_page.dart';
import '../utils/import_book.dart';

Future<Book> importBook(File file) async {
  EpubBookRef epubBookRef = await EpubReader.openBook(file.readAsBytesSync());
  String author = epubBookRef.Author ?? 'Unknown Author';
  String title = epubBookRef.Title ?? 'Unknown';

  final cover = await epubBookRef.readCover();
  final newBookName =
      '${title.length > 20 ? title.substring(0, 20) : title}-$author-${DateTime.now().toString()}';

  // Directory appDocDir = await getApplicationDocumentsDirectory();
  // final fileDir = Directory('${appDocDir.path}/file');
  // final coverDir = Directory('${appDocDir.path}/cover');
  // if (!fileDir.existsSync()) {
  //   fileDir.createSync();
  // }
  // if (!coverDir.existsSync()) {
  //   coverDir.createSync();
  // }
  final relativeFilePath = 'file/$newBookName.epub';
  final filePath = getBasePath(relativeFilePath);
  final relativeCoverPath = 'cover/$newBookName.png';
  final coverPath = getBasePath(relativeCoverPath);

  await file.copy(filePath);
  saveImageToLocal(cover, coverPath);

  Book book = Book(
      id: -1,
      title: title,
      coverPath: relativeCoverPath,
      filePath: relativeFilePath,
      lastReadPosition: '',
      readingPercentage: 0,
      author: author,
      isDeleted: false,
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
      builder: (context) => ReadingPage(book: book),
    ),
  ).then((result) {
    if (result != null) {
      Map<String, dynamic> resultMap = result as Map<String, dynamic>;
      book.lastReadPosition = resultMap['cfi'];
      book.readingPercentage = resultMap['readProgress'];
      print(resultMap);
      updateBook(book);
      updateBookList();
    }
  });
  print('Open book: ${book.title}');
}
