import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

import '../page/reading_page.dart';
import '../utils/import_book.dart';
import '../utils/toast/common.dart';

Future<Book> importBook(File file) async {
  // TODO l10n
  try {
    EpubBookRef epubBookRef = await EpubReader.openBook(file.readAsBytesSync());
    String author = epubBookRef.Author ?? 'Unknown Author';
    String title = epubBookRef.Title ?? 'Unknown';

    final cover = await epubBookRef.readCover();
    final newBookName =
        '${title.length > 20 ? title.substring(0, 20) : title}-${DateTime.now().millisecond.toString()}'.replaceAll(' ', '_');

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
        rating: 0.0,
        createTime: DateTime.now(),
        updateTime: DateTime.now());
    book.id = await insertBook(book);
    return book;
  } catch (e) {
    // TODO l10n
    AnxToast.show('Failed to import book, please check if the book is valid\n[$e]',
        duration: 5000);
    return Book(
      id: -1,
      title: 'Unknown',
      coverPath: '',
      filePath: '',
      lastReadPosition: '',
      readingPercentage: 0,
      author: '',
      isDeleted: false,
      rating: 0.0,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
    );
  }
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

void updateBookRating(Book book, double rating) {
  book.rating = rating;
  updateBook(book);
}
