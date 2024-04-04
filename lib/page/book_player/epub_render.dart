import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EpubRender extends StatefulWidget {
  final String content;

  EpubRender({Key? key, required this.content}) : super(key: key);

  @override
  _EpubRenderState createState() => _EpubRenderState();
}

class _EpubRenderState extends State<EpubRender> {
  late InAppWebViewController _webViewController;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Expanded(
            child: InAppWebView(
              onWebViewCreated: (controller) {
                _webViewController = controller;
                _renderPage();
              },
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _renderPage() async {
    _webViewController.setSettings(
        settings: InAppWebViewSettings(
      enableViewportScale: true,
      builtInZoomControls: false,
      disableHorizontalScroll: true,
      disableVerticalScroll: true,
    ));

    await _webViewController.loadData(
      data: widget.content,
      mimeType: "text/html",
      encoding: "utf8",
    );
  }

  @override
  void didUpdateWidget(covariant EpubRender oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.content != oldWidget.content) {
      _renderPage();
    }
  }
}