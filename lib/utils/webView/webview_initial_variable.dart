import 'package:anx_reader/models/book_style.dart';

String webviewInitialVariable(String allAnnotations, String url, String cfi,
    BookStyle bookStyle, String textColor, String backgroundColor,
    {bool? importing,}) {
  importing ?? false;
  return '''
     console.log(navigator.userAgent)
     const importing = $importing
     const allAnnotations = $allAnnotations
     const url = '$url'
     let cfi = '$cfi'
     let style = {
         fontSize: ${bookStyle.fontSize},
         letterSpacing: ${bookStyle.letterSpacing},
         spacing: ${bookStyle.lineHeight},
         paragraphSpacing: ${bookStyle.paragraphSpacing},
         fontColor: '#$textColor',
         backgroundColor: '#$backgroundColor',
         topMargin: ${bookStyle.topMargin},
         bottomMargin: ${bookStyle.bottomMargin},
         sideMargin: ${bookStyle.sideMargin},
         justify: true,
         hyphenate: true,
         scroll: false,
         animated: true
     }
  ''';
}
