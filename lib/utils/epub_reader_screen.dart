import 'dart:convert';

// import 'dart:html';
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
  int _currentPage = 0;
  String _cssContent = '';
  Map<String, EpubByteContentFile>? _images;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
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
      final imageData = base64Encode(image.Content!);
      final imageUrl = 'data:${image.ContentType};base64,$imageData';
      content = content!.replaceAll('../${image.FileName}', imageUrl);
    }

    final url = Uri.dataFromString(content!,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString();

    _injectCss();

    await _webViewController!.loadUrl(
      urlRequest: URLRequest(url: Uri.parse(url)),
    );
  }

  Future<void> _injectCss() async {
    if (_webViewController == null) return;

    await _webViewController!.evaluateJavascript(source: '''
    var style = document.createElement('style');
    style.type = 'text/css';
    style.innerHTML = `$_cssContent`;
    document.head.appendChild(style);
  ''');
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _loadBook(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        } else if (snapshot.hasError) {
          return Text('Error: ${snapshot.error}');
        } else {
          return Scaffold(
            body: Column(
              children: [
                Expanded(
                  child: InAppWebView(
                    initialOptions: InAppWebViewGroupOptions(
                      crossPlatform: InAppWebViewOptions(),
                    ),
                    initialUrlRequest: URLRequest(
                      url: Uri.parse('about:blank'),
                    ),
                    onWebViewCreated: (controller) {
                      _webViewController = controller;
                      _renderPage(_currentPage);
                    },
                    onLoadStop: (controller, url) {
                      _injectCss();
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
