import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:epub_view/epub_view.dart';
import 'package:epubx/epubx.dart';
import 'package:flutter/material.dart';

import '../../models/EpubPosition.dart';
import '../../service/book_player/book_player.dart';
import 'epub_render.dart';

class EpubPlayer extends StatefulWidget {
  Book book;

  EpubPlayer({super.key, required this.book});

  @override
  State<EpubPlayer> createState() => _EpubPlayerState();
}

class _EpubPlayerState extends State<EpubPlayer> {
  List<EpubRender> _renders = [];

  EpubBook _epubBook = EpubBook();
  late EpubPosition _initialPosition;
  String _cssContent = '';
  Map<String, EpubByteContentFile>? _images;
  int _currentChapter = 0;
  int _currentPage = 0;
  String _currentContent = '';

  @override
  void initState() {
    super.initState();
    loadInitialState();
  }

  Future<void> loadInitialState() async {
    await loadEpubBook();
    _initialPosition = widget.book.lastReadPosition;
    _currentChapter = _initialPosition.chapterIndex ?? 5;
    _currentPage = ((_initialPosition.chapterPageIndex ?? 0) /
            (_initialPosition.chapterLength ?? 1))
        .floor();

    _currentContent = await loadContent(_currentChapter);
    setState(() {
      _renders.add(EpubRender(content: _currentContent));
    });
  }

  loadEpubBook() async {
    _epubBook =
        await EpubReader.readBook(File(widget.book.filePath).readAsBytesSync());
    _cssContent = _epubBook.Content!.Css!.values
        .map((cssFile) => cssFile.Content)
        .join('\n');
    _images = _epubBook.Content!.Images;
  }

  String loadContent(int chapterIndex) {
    String filePath = getChapterFileName(_epubBook, chapterIndex);
    final EpubContentFile? file = _epubBook.Content?.AllFiles?[filePath];
    String content;
    if (file is EpubTextContentFile) {
      content = file.Content!;
    } else if (file is EpubByteContentFile) {
      content = utf8.decode(file.Content!);
    } else {
      return 'Error Epub Content';
    }
    for (final image in _images!.values) {
      if (content.contains('../${image.FileName}') == false) continue;
      final imageData = base64Encode(image.Content!);
      final imageUrl = 'data:${image.ContentType};base64,$imageData';
      content = content.replaceAll('../${image.FileName}', imageUrl);
    }

    _cssContent += '''
       body {
         font-size: 5em !important; 
         padding: 0em 3vw !important;
         width: 100vw; 
         height: 100vh; 
         box-sizing: border-box;
         overflow: hidden;
         hyphens: auto;
         text-align: justify;
         font-family: Arial, sans-serif;
         
         column-width: 100vw;
         column-gap: 6vw;
         column-fill: auto;
         transform: translateX(-${_currentPage * 100}vw);
       }
       
       h2, p {
         page-break-after: always; 
       }
       
       img {
         break-inside: avoid;
       }
       
       p {
           font-family: Arial, sans-serif;
           line-height: 1.5em !important; 
           margin: 0;
           padding: 1.3em 60px !important;
       }
      ''';

    content = '''
     <meta name="viewport" content="width=device-width, height=device-height, initial-scale=0.1">
     <style>$_cssContent</style>
     $content
     ''';

    return content;
  }

  @override
  Widget build(BuildContext context) {
    if (_renders.isEmpty) {
      return Center(child: CircularProgressIndicator());
    }
    // return _renders[0];
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: EpubRender(content: _currentContent),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: const Icon(Icons.navigate_before),
                onPressed: () {
                  setState(() {
                    _currentPage = (_currentPage - 1);
                    _currentContent = loadContent(_currentChapter);
                  });
                },
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: () {
                  setState(() {
                    _currentPage = (_currentPage + 1);
                    _currentContent = loadContent(_currentChapter);
                  });
                },
              ),
            ],
          ),
        ],
      ),
    );
  }
}
