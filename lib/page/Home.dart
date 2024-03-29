import 'dart:io';

import 'package:anx_reader/dao/Book.dart';
import 'package:anx_reader/models/Book.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../widgets.dart';

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
            type: FileType.custom, allowedExtensions: allowBookExtensions))
        ?.files;

    if (selectedBook?.isEmpty ?? true) {
      return;
    }

    final bookPath = selectedBook!.single.path!;
    File file = File(bookPath);
    Book book = Book.byFile(file);

    book.insertToSql();
  }

  Widget _bookList() {
    return FutureBuilder<List<Book>>(
      future: getAllBooks(),
      builder: (BuildContext context, AsyncSnapshot<List<Book>> snapshot) {
        if (snapshot.hasData) {
          return GridView.builder(
            itemCount: snapshot.data!.length,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              childAspectRatio: 0.6,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
            ),
            itemBuilder: (BuildContext context, int index) {
              Book book = snapshot.data![index];
              return BookItem(book: book);
            },
          );
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        }
        return const CircularProgressIndicator();
      },
    );
  }
}
