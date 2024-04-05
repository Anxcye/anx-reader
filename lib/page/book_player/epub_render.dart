import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class EpubRender extends StatefulWidget {
  final String content;
  final int currentPage;
  final Function onTotalColumns;

  EpubRender(
      {Key? key,
      required this.content,
      required this.onTotalColumns,
      required this.currentPage});

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
              initialFile: 'assets/reader.html',
              initialSettings: InAppWebViewSettings(
                allowUniversalAccessFromFileURLs: true,
              ),
              onWebViewCreated: (controller) {
                _webViewController = controller;
              },

            ),
          ),
        ],
      ),
    );
  }

}
