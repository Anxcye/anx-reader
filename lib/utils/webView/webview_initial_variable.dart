import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/utils/js/convert_dart_color_to_js.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:flutter_smart_dialog/flutter_smart_dialog.dart';

void webviewInitialVariable(
  InAppWebViewController controller,
  String url,
  String cfi, {
  BookStyle? bookStyle,
  int? textIndent,
  String? textColor,
  String? fontName,
  String? fontPath,
  String? backgroundColor,
  bool? importing,
}) {
  ReadTheme readTheme = Prefs().readTheme;
  bookStyle ??= Prefs().bookStyle;
  textColor ??= readTheme.textColor;
  fontName ??= Prefs().font.name;
  fontPath ??= Prefs().font.path;
  backgroundColor ??= readTheme.backgroundColor;
  importing ??= false;

  textColor = convertDartColorToJs(textColor);
  backgroundColor = convertDartColorToJs(backgroundColor);

  const minWebviewVersion = 92;

  String replaceSingleQuote(String value) {
    return value.replaceAll("'", "\\'");
  }

  controller.evaluateJavascript(source: '''
    console.log('navigator.userAgent', navigator.userAgent)
  ''');

  final script = '''
     const webviewVersion = navigator.userAgent.match(/Chrome\\/(\\d+)/)?.[1]
     const appleWebkitVersion = navigator.userAgent.match(/AppleWebKit\\/(\\d+)/)?.[1]
     const isApple = navigator.userAgent.includes('Macintosh') || navigator.userAgent.includes('iPhone') || navigator.userAgent.includes('iPad')
     console.log('webviewVersion', webviewVersion)
     console.log('appleWebkitVersion', appleWebkitVersion)
     console.log('isApple', isApple)
     if (
        (!isApple && (webviewVersion && webviewVersion < $minWebviewVersion || !webviewVersion))
        || (isApple && (appleWebkitVersion && appleWebkitVersion < 605 ))
     ) {
       window.flutter_inappwebview.callHandler('webviewVersion', webviewVersion)
     }
     const importing = $importing
     const url = '${replaceSingleQuote(url)}'
     let initialCfi = '${replaceSingleQuote(cfi)}'
     let style = {
         fontSize: ${bookStyle.fontSize},
         fontName: '${replaceSingleQuote(fontName)}',
         fontPath: '${replaceSingleQuote(fontPath)}',
         fontWeight: ${bookStyle.fontWeight},
         letterSpacing: ${bookStyle.letterSpacing},
         spacing: ${bookStyle.lineHeight},
         paragraphSpacing: ${bookStyle.paragraphSpacing},
         textIndent: ${bookStyle.indent},
         fontColor: '#$textColor',
         backgroundColor: '#$backgroundColor',
         topMargin: ${bookStyle.topMargin},
         bottomMargin: ${bookStyle.bottomMargin},
         sideMargin: ${bookStyle.sideMargin},
         justify: true,
         hyphenate: true,
         pageTurnStyle: '${Prefs().pageTurnStyle.name}',
         maxColumnCount: ${bookStyle.maxColumnCount},
     }
        let readingRules = {
          convertChineseMode: '${Prefs().readingRules.convertChineseMode.name}',
          bionicReadingMode: ${Prefs().readingRules.bionicReading},
        }

  ''';
  controller.addJavaScriptHandler(
      handlerName: 'webviewInitialVariable',
      callback: (args) async {
        await controller.evaluateJavascript(source: script);
        return null;
      });
  controller.addJavaScriptHandler(
      handlerName: 'webviewVersion',
      callback: (args) async {
        SmartDialog.show(
          animationType: SmartAnimationType.fade,
          builder: (context) {
            final version = args[0];
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
                      .webview_unsupported_message(minWebviewVersion, version ?? -1)),
                ],
              ),
              actions: [
                TextButton(
                    onPressed: () {
                      SmartDialog.dismiss();
                    },
                    child: Text(L10n.of(context).webview_cancel)),
                // TextButton(
                //     onPressed: () {
                //     },
                //     child: Text(L10n.of(context).webview_update))
              ],
            );
          },
        );
        return null;
      });
}
