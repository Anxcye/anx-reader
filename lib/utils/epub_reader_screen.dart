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
  int _currentPage = 0;

  @override
  void initState() {
    super.initState();
    _loadBook();
  }

  Future<void> _loadBook() async {
    final file = File(widget.epubFilePath);
    _book = await EpubReader.readBook(file.readAsBytes());
    // _renderPage(_currentPage);
  }

  Future<void> _renderPage(int chapterIndex) async {
    if (_book == null || _webViewController == null) return;

    final chapter = _book!.Chapters?[chapterIndex];
    if (chapter == null) return;

    final content = chapter.HtmlContent;
    final url = Uri.dataFromString(content!,
            mimeType: 'text/html', encoding: Encoding.getByName('utf-8'))
        .toString();

    _webViewController!.loadUrl(
      urlRequest: URLRequest(url: Uri.parse(url)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialUrlRequest: URLRequest(
                url: Uri.parse('about:blank'),
              ),
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
                onPressed: _book == null
                    ? null
                    : () {
                  print(_currentPage);
                        setState(() {
                          _currentPage = (_currentPage - 1)
                              .clamp(0, _book!.Chapters!.length - 1);
                        });
                        _renderPage(_currentPage);
                      },
              ),
              IconButton(
                icon: const Icon(Icons.navigate_next),
                onPressed: _book == null
                    ? null
                    : () {
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
}
