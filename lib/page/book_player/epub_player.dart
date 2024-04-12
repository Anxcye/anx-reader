import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/utils/generate_index_html.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
    var content = generateIndexHtml(
        widget.book, widget.style, widget.book.lastReadPosition);
    return content;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          InAppWebView(
            initialSettings: InAppWebViewSettings(),
            onWebViewCreated: (controller) {
              _webViewController = controller;
              _renderPage();
            },
          ),
          Row(
            children: [
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    _webViewController.evaluateJavascript(
                        source: 'rendition.prev()');
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                flex: 2,
                child: GestureDetector(
                  onTap: () {
                    // Show or hide your AppBar and BottomBar here
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
              Expanded(
                flex: 1,
                child: GestureDetector(
                  onTap: () {
                    _webViewController.evaluateJavascript(
                        source: 'rendition.next()');
                  },
                  child: Container(color: Colors.transparent),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
