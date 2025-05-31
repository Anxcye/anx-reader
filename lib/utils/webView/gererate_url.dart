import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/book_style.dart';
import 'package:anx_reader/models/read_theme.dart';
import 'package:anx_reader/service/book_player/book_player_server.dart';
import 'package:anx_reader/utils/js/convert_dart_color_to_js.dart';

String generateUrl(
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
  String indexHtmlPath =
      "http://localhost:${Server().port}/foliate-js/index.html";

  ReadTheme readTheme = Prefs().readTheme;
  bookStyle ??= Prefs().bookStyle;
  textColor ??= readTheme.textColor;
  fontName ??= Prefs().font.name;
  fontPath ??= Prefs().font.path;
  backgroundColor ??= readTheme.backgroundColor;
  importing ??= false;

  textColor = convertDartColorToJs(textColor);
  backgroundColor = convertDartColorToJs(backgroundColor);

  // const importing = $importing
  // const url = '${replaceSingleQuote(url)}'
  // let initialCfi = '${replaceSingleQuote(cfi)}'
  // let style = {
  //     fontSize: ${bookStyle.fontSize},
  //     fontName: '${replaceSingleQuote(fontName)}',
  //     fontPath: '${replaceSingleQuote(fontPath)}',
  //     fontWeight: ${bookStyle.fontWeight},
  //     letterSpacing: ${bookStyle.letterSpacing},
  //     spacing: ${bookStyle.lineHeight},
  //     paragraphSpacing: ${bookStyle.paragraphSpacing},
  //     textIndent: ${bookStyle.indent},
  //     fontColor: '#$textColor',
  //     backgroundColor: '#$backgroundColor',
  //     topMargin: ${bookStyle.topMargin},
  //     bottomMargin: ${bookStyle.bottomMargin},
  //     sideMargin: ${bookStyle.sideMargin},
  //     justify: true,
  //     hyphenate: true,
  //     pageTurnStyle: '${Prefs().pageTurnStyle.name}',
  //     maxColumnCount: ${bookStyle.maxColumnCount},
  // }

  // let readingRules = {
  //   convertChineseMode: '${Prefs().readingRules.convertChineseMode.name}',
  //   bionicReadingMode: ${Prefs().readingRules.bionicReading},
  // }


  Map<String, dynamic> style = {
    'fontSize': bookStyle.fontSize,
    'fontName': fontName,
    'fontPath': fontPath,
    'fontWeight': bookStyle.fontWeight,
    'letterSpacing': bookStyle.letterSpacing,
    'spacing': bookStyle.lineHeight,
    'paragraphSpacing': bookStyle.paragraphSpacing, 
    'textIndent': bookStyle.indent,
    'fontColor': '#$textColor',
    'backgroundColor': '#$backgroundColor',
    'topMargin': bookStyle.topMargin,
    'bottomMargin': bookStyle.bottomMargin,
    'sideMargin': bookStyle.sideMargin, 
    'justify': true,
    'hyphenate': true,
    'pageTurnStyle': Prefs().pageTurnStyle.name,
    'maxColumnCount': bookStyle.maxColumnCount,
    'writingMode': Prefs().writingMode.code,
    'backgroundImage': Prefs().bgimg.url,
    'allowScript': Prefs().enableJsForEpub,
  };

  Map<String, dynamic> readingRules = {
    'convertChineseMode': Prefs().readingRules.convertChineseMode.name,
    'bionicReadingMode': Prefs().readingRules.bionicReading,
  };

  Map<String, dynamic> params = {
    'importing': importing,
    'url': url,
    'initialCfi': cfi,
    'style': style,
    'readingRules': readingRules,
  };

  String query = '';

  for (var key in params.keys) {
    query += '$key=${Uri.encodeComponent(jsonEncode(params[key]))}&';
  }
  //remove last &
  query = query.substring(0, query.length - 1);

  // query += 'importing=$importing';
  // query += '&url=$url';
  // query += '&initialCfi=$cfi';
  // query += '&style=$style';
  // query += '&readingRules=$readingRules';
  // query += '&style=$style';
  // query += '&readingRules=$readingRules';




  final uri =  '$indexHtmlPath?$query';


  return uri;
}
