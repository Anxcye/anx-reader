import 'dart:async';

typedef EpubJavaScriptHandler = FutureOr<dynamic> Function(List<dynamic> args);

class EpubJavaScriptResult {
  const EpubJavaScriptResult({this.value});

  final dynamic value;
}

abstract class EpubWebViewController {
  Future<dynamic> evaluateJavascript({required String source});

  Future<EpubJavaScriptResult> callAsyncJavaScript({
    required String functionBody,
  });

  void addJavaScriptHandler({
    required String handlerName,
    required EpubJavaScriptHandler callback,
  });
}
