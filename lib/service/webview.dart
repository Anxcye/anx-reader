import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/page/home_page.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/webView/webview_console_message.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class WebviewService {
  static final WebviewService _instance = WebviewService._internal();

  factory WebviewService() => _instance;

  WebviewService._internal();

  HeadlessInAppWebView? headlessWebView;

  InAppWebViewController? webViewController;
  Future<void> init() async {
    String indexHtmlPath =
        "http://localhost:${Server().port}/foliate-js/index.html";

    InAppWebViewSettings initialSettings = InAppWebViewSettings(
      supportZoom: false,
      transparentBackground: true,
      isInspectable: kDebugMode,
    );

    Future<void> setHandler(InAppWebViewController controller) async {
      EpubPlayerState? epubPlayerState = epubPlayerKey.currentState;

      controller.addJavaScriptHandler(
          handlerName: 'onLoadEnd',
          callback: (args) {
            epubPlayerState?.onLoadEndHandler(args);
          });

      controller.addJavaScriptHandler(
          handlerName: 'onRelocated',
          callback: (args) {
            epubPlayerState?.onRelocatedHandler(args);
          });
      controller.addJavaScriptHandler(
          handlerName: 'onClick',
          callback: (args) {
            epubPlayerState?.onClickHandler(args);
          });
      controller.addJavaScriptHandler(
          handlerName: 'onSetToc',
          callback: (args) {
            epubPlayerState?.onSetTocHandler(args);
          });
      controller.addJavaScriptHandler(
          handlerName: 'onSelectionEnd',
          callback: (args) {
            epubPlayerState?.onSelectionEndHandler(args);
          });
      controller.addJavaScriptHandler(
          handlerName: 'onAnnotationClick',
          callback: (args) {
            epubPlayerState?.onAnnotationClickHandler(args);
          });
      controller.addJavaScriptHandler(
        handlerName: 'onSearch',
        callback: (args) {
          epubPlayerState?.onSearchHandler(args);
        },
      );
      controller.addJavaScriptHandler(
        handlerName: 'renderAnnotations',
        callback: (args) {
          epubPlayerState?.onRenderAnnotationsHandler(args);
        },
      );
      controller.addJavaScriptHandler(
        handlerName: 'onPushState',
        callback: (args) {
          epubPlayerState?.onPushStateHandler(args);
        },
      );
      controller.addJavaScriptHandler(
        handlerName: 'onImageClick',
        callback: (args) {
          epubPlayerState?.onImageClickHandler(args);
        },
      );
      controller.addJavaScriptHandler(
        handlerName: 'onFootnoteClose',
        callback: (args) {
          epubPlayerState?.onFootnoteCloseHandler(args);
        },
      );
    }

    Future<void> onWebViewCreated(InAppWebViewController controller) async {
      if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
        await InAppWebViewController.setWebContentsDebuggingEnabled(true);
      }
      webViewController = controller;
      setHandler(controller);
    }

    final contextMenu = ContextMenu(
      settings: ContextMenuSettings(hideDefaultSystemContextMenuItems: true),
      onCreateContextMenu: (hitTestResult) async {
        webViewController!.evaluateJavascript(source: "showContextMenu()");
      },
      onHideContextMenu: () {
        epubPlayerKey.currentState?.removeOverlay();
      },
    );
    headlessWebView = HeadlessInAppWebView(
      webViewEnvironment: webViewEnvironment,
      initialUrlRequest: URLRequest(url: WebUri(indexHtmlPath)),
      onConsoleMessage: (controller, consoleMessage) {
        webviewConsoleMessage(controller, consoleMessage);
      },
      onWebViewCreated: (controller) {
        AnxLog.info("onWebViewCreated: ${controller.toString()}");
      },
      initialSettings: initialSettings,
      contextMenu: contextMenu,
      onLoadStop: (controller, url) => onWebViewCreated(controller),
    );
    if (headlessWebView != null && !headlessWebView!.isRunning()) {
      await headlessWebView!.run();
    }
  }

  Future<void> dispose() async {
    await headlessWebView?.dispose();
  }
}
