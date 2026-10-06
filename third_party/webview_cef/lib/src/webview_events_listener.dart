import 'package:webview_cef/src/webview.dart';

typedef TitleChangeCb = void Function(String title);
typedef UrlChangeCb = void Function(String url);
/* Log severity levels. from CEF include/internal/cef_types.h
  0:default logging (currently info logging)
  1:verbose logging or debug logging
  2:info logging
  3:warning logging
  4:error logging
  5:fatal logging
  99:disable logging to file for all messages, and to stderr for messages with severity less than fatal
 */
typedef LoadStartCb = void Function(WebViewController controller, String url);
typedef LoadStopCb = void Function(WebViewController controller, String url);

typedef OnConsoleMessage = void Function(
    int level, String message, String source, int line);

class WebviewEventsListener {
  TitleChangeCb? onTitleChanged;
  UrlChangeCb? onUrlChanged;
  OnConsoleMessage? onConsoleMessage;
  LoadStartCb? onLoadStart;
  LoadStopCb? onLoadEnd;

  WebviewEventsListener({
    this.onTitleChanged,
    this.onUrlChanged,
    this.onConsoleMessage,
    this.onLoadStart,
    this.onLoadEnd,
  });
}
