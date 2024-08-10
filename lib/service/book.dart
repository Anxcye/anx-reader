import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/import_book.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:epubz/epubz.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

Future<Book> importBook(File file) async {
  try {
    EpubBookRef epubBookRef = await EpubReader.openBook(file.readAsBytesSync());
    String author = epubBookRef.Author ?? 'Unknown Author';
    String title = epubBookRef.Title ?? 'Unknown';

    final cover = await epubBookRef.readCover();
    final newBookName =
        '${title.length > 20 ? title.substring(0, 20) : title}-${DateTime.now().millisecond.toString()}'
            .replaceAll(' ', '_');

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
    BuildContext context = navigatorKey.currentContext!;
    AnxToast.show(L10n.of(context).service_import_success);
    return book;
  } catch (e) {
    AnxToast.show(
        'Failed to import book, please check if the book is valid\n[$e]',
        duration: 5000);
    AnxLog.severe('Failed to import book\n$e');
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
  Future.delayed(const Duration(milliseconds: 500), () {
    updateBookList();
  });

  Navigator.push(
      context,
      PageRouteBuilder(
        transitionDuration: const Duration(milliseconds: 500),
        reverseTransitionDuration: const Duration(milliseconds: 500),
        pageBuilder: (context, animation, secondaryAnimation) =>
            ReadingPage(key: readingPageKey, book: book),
      )).then((value) {
    // wait 1s to update book which is read
    Future.delayed(const Duration(milliseconds: 500), () {
      updateBookList();
    });
  });
}

void updateBookRating(Book book, double rating) {
  book.rating = rating;
  updateBook(book);
}

Future<void> resetBookCover(Book book) async {
  File file = File(book.fileFullPath);
  EpubBookRef epubBookRef = await EpubReader.openBook(file.readAsBytesSync());

  final cover = await epubBookRef.readCover();
  final relativeCoverPath =
      'cover/${book.title}-${DateTime.now().millisecond.toString()}.png';
  final coverPath = getBasePath(relativeCoverPath);

  saveImageToLocal(cover, coverPath);

  book.coverPath = relativeCoverPath;
  updateBook(book);
}
