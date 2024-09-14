import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/utils/js/convert_dart_color_to_js.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

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
  textColor ??= convertDartColorToJs(readTheme.textColor);
  fontName ??= Prefs().font.name;
  fontPath ??= Prefs().font.path;
  backgroundColor ??= convertDartColorToJs(readTheme.backgroundColor);
  importing ??= false;

  final script = '''
     console.log(navigator.userAgent)
     const importing = $importing
     const url = '$url'
     let initialCfi = '$cfi'
     let style = {
         fontSize: ${bookStyle.fontSize},
         fontName: '$fontName',
         fontPath: '$fontPath',
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
     }
  ''';
  controller.addJavaScriptHandler(
      handlerName: 'webviewInitialVariable',
      callback: (args) async {
        await controller.evaluateJavascript(source: script);
        return null;
      });
}
