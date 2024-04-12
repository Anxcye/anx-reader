import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';

class ReadingPage extends StatefulWidget {
  final Book book;

  const ReadingPage({super.key, required this.book});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late Book _book;
  EpubContent? _content;
  final _epubPlayerKey = GlobalKey<EpubPlayerState>();

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    initializeContent();
  }

  Future<void> initializeContent() async {
    EpubBookRef epubBookRef =
        await EpubReader.openBook(File(_book.filePath).readAsBytes());
    _content = await EpubReader.readContent(epubBookRef.Content!);
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    if (_content == null) {
      return CircularProgressIndicator();
    } else {
      return PopScope(
        canPop: false,
        onPopInvoked: (bool didPop) async {
          if (didPop) return;
          String cfi = await _epubPlayerKey.currentState!.onReadingLocation();
          Navigator.pop(context, cfi);
        },
        child: Scaffold(
          appBar: AppBar(
            title: Text(_book.title),
          ),
          body: EpubPlayer(
            key: _epubPlayerKey,
            book: _book,
            style: BookStyle(),
          ),
        ),
      );
    }
  }
}
