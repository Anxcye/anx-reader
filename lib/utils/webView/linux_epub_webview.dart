import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/utils/webView/epub_webview_controller.dart';
import 'package:flutter/material.dart';
import 'package:webview_cef/webview_cef.dart' as cef;

const _flutterInAppWebViewBridgeScript = r'''
  window.flutter_inappwebview = window.flutter_inappwebview || {};
  window.flutter_inappwebview.callHandler = function(name, ...args) {
    return new Promise((resolve, reject) => {
      try {
        external.JavaScriptChannel('AnxBridge', { name, args }, (result) => {
          try {
            resolve(JSON.parse(result));
          } catch (_) {
            resolve(result);
          }
        });
      } catch (error) {
        reject(error);
      }
    });
  };
''';

class LinuxEpubWebViewController implements EpubWebViewController {
  LinuxEpubWebViewController(
    this._controller, {
    this.onLoadStop,
    this.onConsoleMessage,
  });

  final cef.WebViewController _controller;
  final void Function(EpubWebViewController controller, Uri? url)? onLoadStop;
  final void Function(int level, String message, String source, int line)?
      onConsoleMessage;
  final Map<String, EpubJavaScriptHandler> _handlers = {};
  final Map<String, Completer<dynamic>> _asyncCalls = {};
  int _nextAsyncCallId = 0;
  bool _listenerAttached = false;

  Future<void> initialize(String url) async {
    if (!_listenerAttached) {
      _controller.setWebviewListener(
        cef.WebviewEventsListener(
          onConsoleMessage: (level, message, source, line) {
            onConsoleMessage?.call(level, message, source, line);
            debugPrint('CEF console[$level] $source:$line $message');
          },
          onLoadEnd: (controller, loadedUrl) {
            onLoadStop?.call(this, Uri.tryParse(loadedUrl));
          },
        ),
      );
      _listenerAttached = true;
    }

    await _controller.initialize('about:blank');
    await _controller.setJavaScriptChannels({
      cef.JavascriptChannel(
        name: 'AnxBridge',
        onMessageReceived: _handleBridgeMessage,
      ),
      cef.JavascriptChannel(
        name: 'AnxEval',
        onMessageReceived: _handleEvalMessage,
      ),
    });
    await _controller.loadUrl(url);
  }

  Widget get widget => ValueListenableBuilder<bool>(
        valueListenable: _controller,
        builder: (context, ready, child) =>
            ready ? _controller.webviewWidget : _controller.loadingWidget,
      );

  Future<void> dispose() => _controller.dispose();

  @override
  Future<dynamic> evaluate(String source) {
    return _controller.evaluateJavascript(source);
  }

  @override
  Future<void> execute(String source) {
    return _controller.executeJavaScript(source);
  }

  @override
  Future<EpubJavaScriptResult> callAsyncJavaScript({
    required String functionBody,
  }) async {
    final id = (_nextAsyncCallId++).toString();
    final completer = Completer<dynamic>();
    _asyncCalls[id] = completer;

    final script = '''
      (() => {
        Promise.resolve((async () => {
          $functionBody
        })()).then((value) => {
          AnxEval({ id: '$id', value });
        }).catch((error) => {
          AnxEval({ id: '$id', error: String(error) });
        });
      })();
    ''';

    await _controller.executeJavaScript(script);
    return EpubJavaScriptResult(value: await completer.future);
  }

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required EpubJavaScriptHandler callback,
  }) {
    _handlers[handlerName] = callback;
  }

  @override
  Future<void> setBrowserFocus(bool focus) {
    return _controller.setClientFocus(focus);
  }

  Future<void> _handleBridgeMessage(cef.JavascriptMessage message) async {
    try {
      final payload = jsonDecode(message.message) as Map<String, dynamic>;
      final name = payload['name'] as String?;
      final args = (payload['args'] as List<dynamic>?) ?? const [];
      final handler = name == null ? null : _handlers[name];
      final result = handler == null ? null : await handler(args);
      await _controller.sendJavaScriptChannelCallBack(
        false,
        jsonEncode(result),
        message.callbackId,
        message.frameId,
      );
    } catch (error) {
      await _controller.sendJavaScriptChannelCallBack(
        true,
        jsonEncode(error.toString()),
        message.callbackId,
        message.frameId,
      );
    }
  }

  void _handleEvalMessage(cef.JavascriptMessage message) {
    final payload = jsonDecode(message.message) as Map<String, dynamic>;
    final id = payload['id']?.toString();
    if (id == null) return;

    final completer = _asyncCalls.remove(id);
    if (completer == null) return;

    if (payload.containsKey('error')) {
      completer.completeError(payload['error'].toString());
    } else {
      completer.complete(payload['value']);
    }
  }
}

class LinuxEpubWebView extends StatefulWidget {
  const LinuxEpubWebView({
    super.key,
    required this.url,
    required this.onWebViewCreated,
    this.onLoadStop,
  });

  final String url;
  final FutureOr<void> Function(EpubWebViewController controller)
      onWebViewCreated;
  final void Function(EpubWebViewController controller, Uri? url)? onLoadStop;

  @override
  State<LinuxEpubWebView> createState() => _LinuxEpubWebViewState();
}

class _LinuxEpubWebViewState extends State<LinuxEpubWebView> {
  late final LinuxEpubWebViewController _controller;

  @override
  void initState() {
    super.initState();
    _controller = LinuxEpubWebViewController(
      cef.WebviewManager().createWebView(
        loading: const Center(child: CircularProgressIndicator()),
        injectUserScripts: cef.InjectUserScripts()
          ..add(
            cef.UserScript(
              _flutterInAppWebViewBridgeScript,
              cef.ScriptInjectTime.LOAD_START,
            ),
          ),
      ),
      onLoadStop: widget.onLoadStop,
    );
    widget.onWebViewCreated(_controller);
    _controller.initialize(widget.url);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return _controller.widget;
  }
}
