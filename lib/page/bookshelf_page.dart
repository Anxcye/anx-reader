import 'dart:io';

import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/widgets/book_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../dao/book.dart';
import '../models/book.dart';
import '../service/book.dart';
import '../widgets/tips/bookshelf_tips.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => _BookshelfPageState();
}

class _BookshelfPageState extends State<BookshelfPage> {
  List<Book> _books = [];

  @override
  void initState() {
    super.initState();
    _refreshBookList();
  }

  Future<void> _refreshBookList() async {
    final books = await selectNotDeleteBooks();
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
        title: Text(context.appName),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _importBook,
          ),
        ],
      ),
      body: _books.isEmpty
          ? const BookshelfTips()
          : BookList(books: _books, onRefresh: _refreshBookList),
    );
  }
}
