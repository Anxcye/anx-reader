import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/webView/webview_console_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebviewService {
  static final WebviewService _instance = WebviewService._internal();

  factory WebviewService() => _instance;

  WebviewService._internal();

  InAppWebViewController? webViewController;
  InAppWebView? webView;
  InAppWebViewKeepAlive? keepAlive;

  bool _isWebViewInitialized = false;
  bool _isWebViewLoaded = false;

  bool _isInitializing = false;

  Widget get webViewWidget => webView ?? const SizedBox();

  bool get isWebViewReady => _isWebViewInitialized && _isWebViewLoaded;

  Future<void> init() async {
    if (_isInitializing || _isWebViewInitialized) {
      return;
    }

    _isInitializing = true;
    AnxLog.info("WebviewService: Starting initialization");

    String indexHtmlPath =
            "http://localhost:${Server().port}/foliate-js/index.html";
        // "https://flutter.dev";
    InAppWebViewSettings initialSettings = InAppWebViewSettings(
      supportZoom: false,
      transparentBackground: true,
      isInspectable: kDebugMode,
    );

    Future<void> onWebViewCreated(InAppWebViewController controller) async {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await InAppWebViewController.setWebContentsDebuggingEnabled(true);
      }
      webViewController = controller;
      // await setHandler(controller);
      _isWebViewInitialized = true;
      AnxLog.info("WebviewService: WebView创建成功");
    }

    keepAlive = InAppWebViewKeepAlive();

    webView = InAppWebView(
      keepAlive: keepAlive,
      webViewEnvironment: webViewEnvironment,
      initialUrlRequest: URLRequest(url: WebUri(indexHtmlPath)),
      onConsoleMessage: (controller, consoleMessage) {
        webviewConsoleMessage(controller, consoleMessage);
      },
      onWebViewCreated: (controller) {
        AnxLog.info("onWebViewCreated: ${controller.toString()}");
      },
      initialSettings: initialSettings,
      // contextMenu: contextMenu,
      onLoadStop: (controller, url) {
        onWebViewCreated(controller);
        _isWebViewLoaded = true;
        _isInitializing = false;
        AnxLog.info("WebviewService: WebView加载完成");
      },
    );

    AnxLog.info("WebviewService: WebView初始化完成");
  }

  void resetWebViewState() {
    AnxLog.info("WebviewService: 重置WebView状态");
    if (webViewController != null) {
      webViewController!.evaluateJavascript(source: "resetReader()");
    }
  }

  Future<bool> ensureWebViewReady() async {
    if (!isWebViewReady) {
      await init();
      int attempts = 0;
      while (!isWebViewReady && attempts < 10) {
        await Future.delayed(const Duration(milliseconds: 200));
        attempts++;
      }
    }
    return isWebViewReady;
  }

  Future<void> dispose() async {
    if (webViewController != null) {
      resetWebViewState();
    }
  }
}
