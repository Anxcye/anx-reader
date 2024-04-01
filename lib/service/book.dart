import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/widgets/book_list.dart';
import 'package:epub_view/epub_view.dart';
import 'package:path_provider/path_provider.dart';

import '../utils/import_book.dart';

Future<Book> importBook(File file) async {
  EpubBook epubBookRef = await EpubDocument.openFile(file);
  String author = epubBookRef.Author ?? 'Unknown Author';
  String title = epubBookRef.Title ?? 'Unknown';
  final cover = epubBookRef.CoverImage;
  final newDirName = '$title - $author';
  final newFileName = '$newDirName.epub';

  Directory appDocDir = await getApplicationDocumentsDirectory();
  final subDir = Directory('${appDocDir.path}/$newDirName');
  await subDir.create(recursive: true);

  final savePath = '${subDir.path}/$newFileName';
  final coverPath = '${subDir.path}/cover.png';

  await file.copy(savePath);
  String filePath = savePath;

  saveImageToLocal(cover!, coverPath);

  String lastReadPosition = '';
  Book book = Book(
      id: -1,
      title: title,
      coverPath: coverPath,
      filePath: filePath,
      lastReadPosition: lastReadPosition,
      author: author,
      createTime: DateTime.now(),
      updateTime: DateTime.now());
  book.id = await insertBook(book);
  return book;
}

void openBook(Book book, Function updateBookList) {
  book.updateTime = DateTime.now();
  updateBook(book);
  Future.delayed(Duration(seconds: 1), () {
    updateBookList();
  });

  print('Open book: ${book.title}');
}
