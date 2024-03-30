import 'dart:io';

import 'package:anx_reader/widgets/book_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../dao/book.dart';
import '../models/book.dart';
import '../service/book.dart';

class BookShelf extends StatefulWidget {
  const BookShelf({super.key});

  @override
  State<BookShelf> createState() => _BookShelfState();
}

class _BookShelfState extends State<BookShelf> {

  List<Book> _books = [];
  int _currentIndex = 0;

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
      body: BookList(books: _books),
    );
  }
}
