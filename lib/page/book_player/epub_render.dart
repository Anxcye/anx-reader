import 'dart:convert';

import 'dart:io';
import 'package:epub_view/epub_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EpubReaderScreen extends StatefulWidget {
  final String epubFilePath;

  const EpubReaderScreen({Key? key, required this.epubFilePath})
      : super(key: key);

  @override
  _EpubReaderScreenState createState() => _EpubReaderScreenState();
}

class _EpubReaderScreenState extends State<EpubReaderScreen> {
  InAppWebViewController? _webViewController;
  EpubBook? _book;
  String _cssContent = '';
  int _currentPage = 0;
  Map<String, EpubByteContentFile>? _images;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    print('Loading book: ${widget.epubFilePath}');
    final file = File(widget.epubFilePath);
    _book = await EpubReader.readBook(file.readAsBytes());

    _cssContent = _book!.Content!.Css!.values
        .map((cssFile) => cssFile.Content)
        .join('\n');
    _images = _book!.Content!.Images;
  }

  Future<void> _renderPage(int chapterIndex) async {
    if (_book == null || _webViewController == null) return;

    final chapter = _book!.Chapters?[chapterIndex];
    if (chapter == null) return;

    var content = chapter.HtmlContent;

    for (final image in _images!.values) {
      if (content!.contains('../${image.FileName}') == false) continue;
      final imageData = base64Encode(image.Content!);
      final imageUrl = 'data:${image.ContentType};base64,$imageData';
      content = content.replaceAll('../${image.FileName}', imageUrl);
    }

    _cssContent += '''
       body {
         width: 100vw; 
         height: 100vh; 
         box-sizing: border-box;
         overflow: hidden;
         hyphens: auto;
         text-align: justify;
         font-size: 7em; 
         font-family: Arial, sans-serif;
       
         column-width: 100vw;
         column-gap: 0;
         column-fill: auto;
         transform: translateX(-100vw);
       }
       
       h2, p {
         page-break-after: always; 
       }
       
       img {
         break-inside: avoid;
       }
       
       p {
           // font-size: 50em;
           font-family: Arial, sans-serif;
           line-height: 1.5em !important; 
           margin: 0;
           padding: 2em 0.2em;
       }
      ''';

    content = '''
     <meta name="viewport" content="width=device-width, height=device-height, initial-scale=0.1">
     <style>$_cssContent</style>
     $content
     ''';


    _webViewController?.setSettings(
        settings: InAppWebViewSettings(
          enableViewportScale: true,
            builtInZoomControls: false,
            disableHorizontalScroll: true,
            // disallowOverScroll: true,
            // initialScale: 110,
            // pageZoom: 1.0,
            //useWideViewPort: true,
            ));

    await _webViewController!.loadData(
      data: content,
      mimeType: "text/html",
      encoding: "utf8",
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadBook(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: InAppWebView(
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                      _renderPage(_currentPage);
                    },
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.navigate_before),
                      onPressed: () {
                        setState(() {
                          _currentPage = (_currentPage - 1)
                              .clamp(0, _book!.Chapters!.length - 1);
                        });
                        _renderPage(_currentPage);
                      },
                    ),
                    IconButton(
                      icon: const Icon(Icons.navigate_next),
                      onPressed: () {
                        setState(() {
                          _currentPage = (_currentPage + 1)
                              .clamp(0, _book!.Chapters!.length - 1);
                        });
                        _renderPage(_currentPage);
                      },
                    ),
                  ],
                ),
              ],
            ),
          );
        }
      },
    );
  }
}
