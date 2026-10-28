import 'dart:async';

typedef EpubJavaScriptHandler = FutureOr<dynamic> Function(List<dynamic> args);

class EpubJavaScriptResult {
  const EpubJavaScriptResult({this.value});

  final dynamic value;
}

/// Platform-agnostic EPUB reader webview controller.
///
/// Prefer [evaluate] when a return value is needed (matches InAppWebView
/// `evaluateJavascript`), and [execute] for fire-and-forget scripts (maps to
/// CEF `executeJavaScript` on Linux; still uses evaluateJavascript on other
/// platforms where that is the only API).
abstract class EpubWebViewController {
  /// Run [source] and return its completion value.
  Future<dynamic> evaluate(String source);

  /// Run [source] without using a return value.
  Future<void> execute(String source);

  Future<EpubJavaScriptResult> callAsyncJavaScript({
    required String functionBody,
  });

  void addJavaScriptHandler({
    required String handlerName,
    required EpubJavaScriptHandler callback,
  });

  /// Release or claim native browser keyboard focus (CEF). No-op on InApp.
  Future<void> setBrowserFocus(bool focus);
}
