import 'dart:io';

import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:anx_reader/utils/webdav/show_status.dart';
import 'package:anx_reader/widgets/book_list.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

import '../../dao/book.dart';
import '../../models/book.dart';
import '../../service/book.dart';
import '../../widgets/tips/bookshelf_tips.dart';

class BookshelfPage extends StatefulWidget {
  const BookshelfPage({super.key});

  @override
  State<BookshelfPage> createState() => BookshelfPageState();

  void refreshBookList() {
    BookshelfPageState().refreshBookList();
  }
}

class BookshelfPageState extends State<BookshelfPage>
    with SingleTickerProviderStateMixin {
  List<Book> _books = [];
  AnimationController? _syncAnimationController;

  @override
  void dispose() {
    _syncAnimationController?.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _syncAnimationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    )..repeat();
    refreshBookList();
  }

  Future<void> refreshBookList() async {
    final books = await selectNotDeleteBooks();
    if (mounted) {
      setState(() {
        _books = books;
      });
    }
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

    refreshBookList();
  }

  Widget syncButton() {
    return StreamBuilder<bool>(
      stream: AnxWebdav.syncing,
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data == true) {
          _syncAnimationController?.repeat();
          return IconButton(
            icon: RotationTransition(
              turns: Tween(begin: 1.0, end: 0.0)
                  .animate(_syncAnimationController!),
              child: const Icon(Icons.sync),
            ),
            onPressed: () {
              // AnxWebdav.syncData(SyncDirection.both);
              showWebdavStatus();
            },
          );
        } else {
          return IconButton(
            icon: const Icon(Icons.sync),
            onPressed: () {
              AnxWebdav.syncData(SyncDirection.both);
            },
          );
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.appName),
        actions: [
          syncButton(),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: _importBook,
          ),
        ],
      ),
      body: _books.isEmpty
          ? const BookshelfTips()
          : BookList(books: _books, onRefresh: refreshBookList),
    );
  }
}
