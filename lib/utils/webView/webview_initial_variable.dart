import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/book_style.dart';

String webviewInitialVariable(
  String allAnnotations,
  String url,
  String cfi,
  BookStyle bookStyle,
  String textColor,
  String backgroundColor, {
  bool? importing,
}) {
  importing ?? false;
  String fontName = Prefs().font.name;
  String fontPath = Prefs().font.path;

  return '''
     console.log(navigator.userAgent)
     const importing = $importing
     const allAnnotations = $allAnnotations
     const url = '$url'
     let cfi = '$cfi'
     let style = {
         fontSize: ${bookStyle.fontSize},
         fontName: '$fontName',
         fontPath: '$fontPath',
         letterSpacing: ${bookStyle.letterSpacing},
         spacing: ${bookStyle.lineHeight},
         paragraphSpacing: ${bookStyle.paragraphSpacing},
         textIndent: 0,
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
}
