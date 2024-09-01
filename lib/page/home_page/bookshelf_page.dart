import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/utils/webdav/common.dart';
import 'package:anx_reader/utils/webdav/show_status.dart';
import 'package:anx_reader/widgets/book_list.dart';
import 'package:anx_reader/widgets/tips/bookshelf_tips.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';

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
    final allowBookExtensions = ["epub", "mobi", "azw3", "fb2"];
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result == null) {
      return;
    }

    List<PlatformFile> files = result.files;
    List<PlatformFile> supportedFiles = files.where((file) {
      return allowBookExtensions.contains(file.extension);
    }).toList();
    List<PlatformFile> unsupportedFiles = files.where((file) {
      return !allowBookExtensions.contains(file.extension);
    }).toList();

    // delete unsupported files
    for (var file in unsupportedFiles) {
      File(file.path!).deleteSync();
    }

    Widget bookItem(String name, Icon icon) {
      return Row(
        children: [
          icon,
          Expanded(
            child: Text(
              name,
              style: const TextStyle(
                  fontWeight: FontWeight.w300,
                  // fontSize: ,
                  overflow: TextOverflow.ellipsis),
            ),
          ),
        ],
      );
    }

    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text(L10n.of(context).import_n_books_selected(files.length)),
            content: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(L10n.of(context)
                      .import_support_types(allowBookExtensions.join(' / '))),
                  const SizedBox(height: 10),
                  if (unsupportedFiles.isNotEmpty)
                    Text(L10n.of(context)
                        .import_n_books_not_support(unsupportedFiles.length)),
                  const SizedBox(height: 20),
                  for (var file in unsupportedFiles)
                    bookItem(file.name, const Icon(Icons.error)),
                  for (var file in supportedFiles)
                    bookItem(file.name, const Icon(Icons.done)),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(context);
                  for (var file in supportedFiles) {
                    File(file.path!).deleteSync();
                  }
                },
                child: Text(L10n.of(context).common_cancel),
              ),
              if (supportedFiles.isNotEmpty)
                TextButton(
                    onPressed: () async {
                      for (var file in supportedFiles) {
                        AnxToast.show(file.name);
                        await importBook(File(file.path!), refreshBookList);
                      }
                      Navigator.of(context).pop('dialog');
                    },
                    child: Text(L10n.of(context)
                        .import_import_n_books(supportedFiles.length))),
            ],
          );
        });


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
        title: Text(L10n.of(context).appName),
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
