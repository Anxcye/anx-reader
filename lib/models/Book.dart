import 'dart:io';
import 'package:epub_view/epub_view.dart';
import 'package:path_provider/path_provider.dart';
import '../utils/importBook.dart';

class Book {
  late int id;
  late String title;
  late String coverPath;
  late String filePath;
  late String lastReadPosition;
  late String author;
  String? description;

  Book(File file) {
    title = '';
    coverPath = '';
    filePath = '';
    lastReadPosition = '';
    author = '';
    _initializeBook(file);
  }

  Future<void> _initializeBook(File file) async {
    EpubBook epubBookRef = await EpubDocument.openFile(file);
    author = epubBookRef.Author ?? 'Unknown Author';
    title = epubBookRef.Title ?? 'Unknown';
    final cover = epubBookRef.CoverImage;
    final newDirName = '$title - $author';
    final newFileName = '$newDirName.epub';

    Directory appDocDir = await getApplicationDocumentsDirectory();
    final subDir = Directory('${appDocDir.path}/$newDirName');
    await subDir.create(recursive: true);

    final savePath = '${subDir.path}/$newFileName';
    final coverPath = '${subDir.path}/cover.png';

    await file.copy(savePath);
    filePath = savePath;

    saveImageToLocal(cover!, coverPath);
    this.coverPath = coverPath;

    lastReadPosition = '';
    print(this.toMap());
  }

  Map<String, Object?> toMap() {
    return {
      'title': title,
      'cover_path': coverPath,
      'file_path': filePath,
      'last_read_position': lastReadPosition,
      'author': author,
      'description': description,
    };
  }
}
