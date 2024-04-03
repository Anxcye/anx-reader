import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EpubRender extends StatelessWidget {
  late final String content;
  InAppWebViewController? _webViewController;

  EpubRender({super.key, required this.content});

  Future<void> _renderPage() async {
    _webViewController?.setSettings(
        settings: InAppWebViewSettings(
      enableViewportScale: true,
      builtInZoomControls: false,
      disableHorizontalScroll: true,
      disableVerticalScroll: true,
    ));

    await _webViewController!.loadData(
      data: content,
      mimeType: "text/html",
      encoding: "utf8",
    );
  }

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
}
