import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/utils/epub_reader_screen.dart';
import 'package:anx_reader/utils/epub_render.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';

class EpubPlayer extends StatefulWidget {
  final Book book;

  const EpubPlayer({super.key, required this.book});

  @override
  State<EpubPlayer> createState() => _EpubPlayerState();
}

class _EpubPlayerState extends State<EpubPlayer> {
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
        body: EpubReaderScreen(epubFilePath: _book.filePath),
        // EpubRenderer(book: _book,),
      );
    }
  }
}