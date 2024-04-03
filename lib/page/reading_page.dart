import 'dart:io';

import 'package:anx_reader/models/EpubPosition.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/page/book_player/epub_render.dart';
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

  @override
  void initState() {
    super.initState();
    _book = widget.book;
    initializeContent();
  }

  Future<void> initializeContent() async {
    EpubBookRef epubBookRef = await EpubReader.openBook(File(_book.filePath).readAsBytes());
    _content = await EpubReader.readContent(epubBookRef.Content!);
    setState(() {}); // Call setState to trigger a rebuild once _content is initialized
  }

  @override
  Widget build(BuildContext context){
    if (_content == null) {
      return CircularProgressIndicator(); // Show a loading spinner while _content is being initialized
    } else {
      return Scaffold(
        appBar: AppBar(
          title: Text(_book.title),
        ),
        body: EpubPlayer(book: _book),
        // EpubRenderer(book: _book,),
      );
    }
  }
}