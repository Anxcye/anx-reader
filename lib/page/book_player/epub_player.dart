import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EpubPlayer extends StatefulWidget {
  final String content;
  final Function showOrHideAppBarAndBottomBar;

  EpubPlayer(
      {Key? key,
      required this.content,
      required this.showOrHideAppBarAndBottomBar})
      : super(key: key);

  @override
  State<EpubPlayer> createState() => EpubPlayerState();
}

class EpubPlayerState extends State<EpubPlayer> {
  late InAppWebViewController _webViewController;

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
      data: widget.content,
      mimeType: "text/html",
      encoding: "utf8",
    );
  }

  @override
  void initState() {
    super.initState();
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
                    widget.showOrHideAppBarAndBottomBar();
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
