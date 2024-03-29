import 'dart:io';

import 'package:anx_reader/utils/importBook.dart';
import 'package:epub_view/epub_view.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anx Reader'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _importBook,
          ),
        ],
      ),
      body: _bookList(),
    );
  }

  Future<void> _importBook() async {
    final allowBookExtensions = ['epub'];
    final selectedBook = (await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: allowBookExtensions
    ))?.files;

    if (selectedBook?.isEmpty ?? true) {
      return;
    }

    final bookPath = selectedBook!.single.path!;
    File file = File(bookPath);

    EpubBook epubBookRef = await EpubDocument.openFile(file);
    final author = epubBookRef.Author;
    final title = epubBookRef.Title;
    final cover = epubBookRef.CoverImage;

    final newDirName = '${title ?? 'Unknown'} - ${author ?? 'Unknown Author'}';
    final newFileName = '$newDirName.epub';

    Directory appDocDir = await getApplicationDocumentsDirectory();
    final subDir = Directory('${appDocDir.path}/$newDirName');

    await subDir.create(recursive: true);
    final savePath = '${subDir.path}/$newFileName';
    final coverPath = '${subDir.path}/cover.png';

    print(file.path);
    print(subDir);
    print(savePath);
    await file.copy(savePath);
    saveImageToLocal(cover!, coverPath);

    print('Saved to $savePath');

  }

  Widget _bookList() {
    return const Text('data');
  }
}
