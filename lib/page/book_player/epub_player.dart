
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/utils/generate_index_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import '../../dao/book.dart';
import '../../models/book_style.dart';

class EpubPlayer extends StatefulWidget {
  Book book;
  BookStyle style;

  EpubPlayer({super.key, required this.book, required this.style});

  @override
  State<EpubPlayer> createState() => EpubPlayerState();
}

class EpubPlayerState extends State<EpubPlayer> {
  late InAppWebViewController _webViewController;
  String _currentContent = '';

  Future<String> onReadingLocation() async {
    print('xx');
    String currentCfi = '';
    _webViewController.addJavaScriptHandler(
        handlerName: 'onReadingLocation',
        callback: (args) {
          currentCfi = args[0];
        });
    await _webViewController.evaluateJavascript(source: '''
      var currentLocation = rendition.currentLocation();
      var currentCfi = currentLocation.start.cfi;
      window.flutter_inappwebview.callHandler('onReadingLocation', currentCfi);
      ''');
    print('currentCfi: $currentCfi');
    return currentCfi;
  }

  Future<void> _renderPage() async {
    await _webViewController.loadData(
      data: _currentContent,
      mimeType: "text/html",
      encoding: "utf8",
    );
  }

  @override
  void initState() {
    super.initState();
    _currentContent = loadContent();
  }

  String loadContent() {
    var content = generateIndexHtml(widget.book, widget.style, widget.book.lastReadPosition);
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          onReadingLocation();
        },
        child: Icon(Icons.location_on),
      ),
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              initialSettings: InAppWebViewSettings(),
              onWebViewCreated: (controller) {
                _webViewController = controller;
                _renderPage();
              },
            ),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  _webViewController.evaluateJavascript(
                      source: 'rendition.prev()');
                },
              ),
              IconButton(
                icon: Icon(Icons.arrow_forward),
                onPressed: () {
                  _webViewController.evaluateJavascript(
                      source: 'rendition.next()');
                },
              ),
            ],
          )
        ],
      ),
    );
  }
}