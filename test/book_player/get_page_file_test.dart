import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/service/book_player/book_player.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter_test/flutter_test.dart';

getFilePageTest() async {
      String path = '/home/axy/other/小王子.epub';
      EpubBook epubBook = await EpubReader.readBook(File(path).readAsBytesSync());
      int page = 2;
      final file = await getPageFile(epubBook, page);
      print(file);
      expect(file, isNotNull);
}
