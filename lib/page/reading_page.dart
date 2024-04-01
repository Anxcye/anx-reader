import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';

class ReadingPage extends StatefulWidget {
  final Book book;

  const ReadingPage({super.key, required this.book});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late EpubController _epubController;
  late Book _book;

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    print(_book.filePath);
    _epubController = EpubController(
      document: EpubDocument.openFile(File(_book.filePath)),
      // Set start point
      // epubCfi: 'epubcfi(/6/6[chapter-2]!/4/2/1612)',
    );
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        appBar: AppBar(
          // Show actual chapter name
          title: EpubViewActualChapter(
              controller: _epubController,
              builder: (chapterValue) => Text(
                    'Chapter: ${chapterValue?.chapter?.Title?.replaceAll('\n', '').trim() ?? ''}',
                    textAlign: TextAlign.start,
                  )),
        ),
        // Show table of contents
        drawer: Drawer(
          child: EpubViewTableOfContents(
            controller: _epubController,
          ),
        ),
        // Show epub document
        body: EpubView(
          controller: _epubController,
        ),
      );
}
