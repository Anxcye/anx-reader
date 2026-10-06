import 'dart:async';

import 'package:anx_reader/utils/platform_utils.dart';
import 'package:anx_reader/utils/webView/epub_webview_controller.dart';
import 'package:anx_reader/utils/webView/in_app_epub_webview_controller.dart';
import 'package:anx_reader/utils/webView/linux_epub_webview.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

/// Single entry widget that picks InAppWebView or Linux CEF.
class EpubWebView extends StatelessWidget {
  const EpubWebView({
    super.key,
    required this.url,
    required this.onWebViewCreated,
    this.onLoadStop,
    this.onConsoleMessage,
    this.initialSettings,
    this.contextMenu,
    this.webViewEnvironment,
  });

  final String url;
  final FutureOr<void> Function(EpubWebViewController controller)
      onWebViewCreated;
  final void Function(EpubWebViewController controller, Uri? url)? onLoadStop;
  final void Function(
          InAppWebViewController controller, ConsoleMessage message)?
      onConsoleMessage;
  final InAppWebViewSettings? initialSettings;
  final ContextMenu? contextMenu;
  final WebViewEnvironment? webViewEnvironment;

  @override
  Widget build(BuildContext context) {
    if (AnxPlatform.isLinux) {
      return LinuxEpubWebView(
        url: url,
        onWebViewCreated: onWebViewCreated,
        onLoadStop: onLoadStop,
      );
    }

    late InAppEpubWebViewController wrapped;
    return InAppWebView(
      webViewEnvironment: webViewEnvironment,
      initialUrlRequest: URLRequest(url: WebUri(url)),
      initialSettings: initialSettings,
      contextMenu: contextMenu,
      onWebViewCreated: (controller) {
        wrapped = InAppEpubWebViewController(controller);
        onWebViewCreated(wrapped);
      },
      onLoadStop: (controller, uri) {
        onLoadStop?.call(wrapped, uri);
      },
      onConsoleMessage: onConsoleMessage,
    );
  }
}
