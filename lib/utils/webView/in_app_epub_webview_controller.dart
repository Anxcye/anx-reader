import 'package:anx_reader/utils/webView/epub_webview_controller.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

class InAppEpubWebViewController implements EpubWebViewController {
  InAppEpubWebViewController(this._controller);

  final InAppWebViewController _controller;

  InAppWebViewController get rawController => _controller;

  @override
  Future<dynamic> evaluateJavascript({required String source}) {
    return _controller.evaluateJavascript(source: source);
  }

  @override
  Future<EpubJavaScriptResult> callAsyncJavaScript({
    required String functionBody,
  }) async {
    final result = await _controller.callAsyncJavaScript(
      functionBody: functionBody,
    );
    return EpubJavaScriptResult(value: result?.value);
  }

  @override
  void addJavaScriptHandler({
    required String handlerName,
    required EpubJavaScriptHandler callback,
  }) {
    _controller.addJavaScriptHandler(
      handlerName: handlerName,
      callback: callback,
    );
  }
}
