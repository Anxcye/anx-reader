import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/service/book_player/book_player.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter_test/flutter_test.dart';

getFilePageTest() async {
      String path = '/home/axy/other/白夜行.epub';
      EpubBook epubBook = await EpubReader.readBook(File(path).readAsBytesSync());
      for (int i = 0; i < epubBook.Chapters!.length; i++) {
        EpubChapter chapter = epubBook.Chapters![i];
      final file = await getChapterFileName(epubBook, i);

        print(file);
        // print(chapter.HtmlContent);
      }
}
