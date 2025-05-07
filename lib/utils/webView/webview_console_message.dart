import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

const minWebviewVersion = 92;
void showUnsupportedWebviewDialog(int version) {
  SmartDialog.show(
    animationType: SmartAnimationType.fade,
    builder: (context) {
      return AlertDialog(
        title: const Center(
          child: Icon(Icons.warning_rounded),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(L10n.of(context).webview_unsupported_version,
                style: Theme.of(context).textTheme.titleMedium),
            Text(L10n.of(context)
                .webview_unsupported_message(minWebviewVersion, version)),
          ],
        ),
        actions: [
          TextButton(
              onPressed: () {
                SmartDialog.dismiss();
              },
              child: Text(L10n.of(context).webview_cancel)),
        ],
      );
    },
  );
}

void handleWebviewVersion(String message) {
  try {
    int webviewVersion =
        int.tryParse(message.split('Chrome/')[1].split('.')[0]) ?? -1;
    int appleWebkitVersion =
        int.tryParse(message.split('AppleWebKit/')[1].split('.')[0]) ?? -1;

    bool isApple = defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;

    if ((!isApple && (webviewVersion < minWebviewVersion)) ||
        (isApple && (appleWebkitVersion < 605))) {
      showUnsupportedWebviewDialog(webviewVersion);
    }
  } catch (e) {
    AnxLog.severe('Webview: $e');
  }
}

void webviewConsoleMessage(
  InAppWebViewController controller,
  ConsoleMessage consoleMessage,
) {
  if (consoleMessage.message.contains(
      "An iframe which has both allow-scripts and allow-same-origin for its sandbox attribute can escape its sandboxing")) {
    return;
  }

  if (consoleMessage.messageLevel == ConsoleMessageLevel.LOG) {
    AnxLog.info('Webview: ${consoleMessage.message}');
    if (consoleMessage.message.contains("AnxUA")) {
      handleWebviewVersion(consoleMessage.message);
    }
  } else if (consoleMessage.messageLevel == ConsoleMessageLevel.WARNING) {
    AnxLog.warning('Webview: ${consoleMessage.message}');
  } else if (consoleMessage.messageLevel == ConsoleMessageLevel.ERROR) {
    AnxLog.severe('Webview: ${consoleMessage.message}');
  }
}
