import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

void webviewConsoleMessage(controller, consoleMessage) {
  if (consoleMessage.message.contains(
      "An iframe which has both allow-scripts and allow-same-origin for its sandbox attribute can escape its sandboxing")) {
    return;
  }
  if (consoleMessage.messageLevel == ConsoleMessageLevel.LOG) {
    AnxLog.info('Webview: ${consoleMessage.message}');
  } else if (consoleMessage.messageLevel == ConsoleMessageLevel.WARNING) {
    AnxLog.warning('Webview: ${consoleMessage.message}');
  } else if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
    AnxLog.severe('Webview: ${consoleMessage.message}');
  }
}
