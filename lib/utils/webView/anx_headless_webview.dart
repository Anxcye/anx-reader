import 'dart:io';

import 'package:anx_reader/main.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:anx_reader/utils/webView/epub_webview_controller.dart';
import 'package:anx_reader/utils/webView/in_app_epub_webview_controller.dart';
import 'package:anx_reader/utils/webView/linux_epub_webview.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

typedef AnxHeadlessCreatedCallback = void Function(
    EpubWebViewController controller);
typedef AnxHeadlessLoadStopCallback = void Function(
    EpubWebViewController controller, Uri? url);
typedef AnxHeadlessConsoleCallback = void Function(
    EpubWebViewController controller, String message,
    {required bool isError});
typedef AnxHeadlessLoadErrorCallback = void Function(
    EpubWebViewController controller, Uri? url, int code, String message);

/// Headless (or offstage) webview for import/search.
///
/// Callers only see [EpubWebViewController] — Linux uses an offstage CEF
/// view; other platforms use HeadlessInAppWebView (with overlay fallback).
class AnxHeadlessWebView {
  HeadlessInAppWebView? _headlessWebView;
  OverlayEntry? _overlayEntry;
  EpubWebViewController? _controller;

  final String initialUrl;
  final InAppWebViewSettings? initialSettings;
  final AnxHeadlessCreatedCallback? onWebViewCreated;
  final AnxHeadlessLoadStopCallback? onLoadStop;
  final AnxHeadlessConsoleCallback? onConsoleMessage;
  final AnxHeadlessLoadErrorCallback? onLoadError;
  final AnxHeadlessLoadErrorCallback? onLoadHttpError;
  final WebViewEnvironment? webViewEnvironment;

  AnxHeadlessWebView({
    required this.initialUrl,
    this.initialSettings,
    this.onWebViewCreated,
    this.onLoadStop,
    this.onConsoleMessage,
    this.onLoadError,
    this.onLoadHttpError,
    this.webViewEnvironment,
  });

  Future<void> run() async {
    if (AnxPlatform.isLinux) {
      _runLinuxCefOverlay();
      return;
    }

    bool useOverlay = false;
    try {
      if (Platform.operatingSystem == 'ohos') {
        useOverlay = true;
      }
    } catch (_) {
      // ignore
    }

    if (Platform.isWindows && webViewEnvironment == null) {
      AnxLog.severe(
          'AnxHeadlessWebView: webViewEnvironment is null on Windows, falling back to Overlay');
      _runInAppOverlay();
      return;
    }

    if (useOverlay) {
      _runInAppOverlay();
      return;
    }

    _headlessWebView = HeadlessInAppWebView(
      webViewEnvironment: webViewEnvironment,
      initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
      initialSettings: initialSettings,
      onWebViewCreated: (controller) {
        final wrapped = InAppEpubWebViewController(controller);
        _controller = wrapped;
        onWebViewCreated?.call(wrapped);
      },
      onLoadStop: (controller, url) {
        final wrapped = _controller ?? InAppEpubWebViewController(controller);
        onLoadStop?.call(wrapped, url);
      },
      onConsoleMessage: (controller, message) {
        final wrapped = _controller ?? InAppEpubWebViewController(controller);
        onConsoleMessage?.call(
          wrapped,
          message.message,
          isError: message.messageLevel == ConsoleMessageLevel.ERROR,
        );
      },
      onLoadError: (controller, url, code, message) {
        final wrapped = _controller ?? InAppEpubWebViewController(controller);
        onLoadError?.call(wrapped, url, code, message);
      },
      onLoadHttpError: (controller, url, statusCode, description) {
        final wrapped = _controller ?? InAppEpubWebViewController(controller);
        onLoadHttpError?.call(wrapped, url, statusCode, description);
      },
    );
    try {
      await _headlessWebView?.run();
    } catch (e) {
      AnxLog.info(
          "HeadlessInAppWebView failed to run, falling back to Overlay: $e");
      _headlessWebView = null;
      _runInAppOverlay();
    }
  }

  void _runLinuxCefOverlay() {
    final context = navigatorKey.currentContext;
    if (context == null) {
      AnxLog.severe(
          "No context available for AnxHeadlessWebView Linux overlay");
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Offstage(
        offstage: true,
        child: SizedBox(
          width: 1,
          height: 1,
          child: LinuxEpubWebView(
            url: initialUrl,
            onWebViewCreated: (controller) {
              _controller = controller;
              onWebViewCreated?.call(controller);
            },
            onLoadStop: (controller, url) {
              onLoadStop?.call(controller, url);
            },
          ),
        ),
      ),
    );
    Overlay.of(context).insert(_overlayEntry!);
  }

  void _runInAppOverlay() {
    final context = navigatorKey.currentContext;
    if (context == null) {
      AnxLog.severe("No context available for AnxHeadlessWebView overlay");
      return;
    }

    _overlayEntry = OverlayEntry(
      builder: (context) => Offstage(
        offstage: true,
        child: SizedBox(
          width: 1,
          height: 1,
          child: InAppWebView(
            initialUrlRequest: URLRequest(url: WebUri(initialUrl)),
            initialSettings: initialSettings,
            onWebViewCreated: (controller) {
              final wrapped = InAppEpubWebViewController(controller);
              _controller = wrapped;
              onWebViewCreated?.call(wrapped);
            },
            onLoadStop: (controller, url) {
              final wrapped =
                  _controller ?? InAppEpubWebViewController(controller);
              onLoadStop?.call(wrapped, url);
            },
            onConsoleMessage: (controller, message) {
              final wrapped =
                  _controller ?? InAppEpubWebViewController(controller);
              onConsoleMessage?.call(
                wrapped,
                message.message,
                isError: message.messageLevel == ConsoleMessageLevel.ERROR,
              );
            },
            onLoadError: (controller, url, code, message) {
              final wrapped =
                  _controller ?? InAppEpubWebViewController(controller);
              onLoadError?.call(wrapped, url, code, message);
            },
            onLoadHttpError: (controller, url, statusCode, description) {
              final wrapped =
                  _controller ?? InAppEpubWebViewController(controller);
              onLoadHttpError?.call(wrapped, url, statusCode, description);
            },
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_overlayEntry!);
  }

  Future<void> dispose() async {
    if (_headlessWebView != null) {
      await _headlessWebView?.dispose();
      _headlessWebView = null;
    }
    if (_overlayEntry != null) {
      _overlayEntry?.remove();
      _overlayEntry = null;
    }
    _controller = null;
  }
}
