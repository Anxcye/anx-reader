import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/service/book.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../widgets/book_item.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    _refreshBookList();
  }

  Future<void> _refreshBookList() async {
    final books = await getAllBooks();
    setState(() {
      _books = books;
    });
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

    await importBook(file);

    _refreshBookList();
  }

  Widget _bookList() {
    return GridView.builder(
      itemCount: _books.length,
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        childAspectRatio: 0.6,
        mainAxisSpacing: 10,
        crossAxisSpacing: 10,
      ),
      itemBuilder: (BuildContext context, int index) {
        Book book = _books[index];
        return BookItem(book: book);
      },
    );
  }

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
}
