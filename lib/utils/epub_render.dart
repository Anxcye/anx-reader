// import 'dart:io';
//
// import 'package:epubx/epubx.dart';
// import 'package:flutter/material.dart';
// import 'package:html/dom.dart' as html;
// import 'package:html/parser.dart' show parse;
// import 'package:flutter_html/flutter_html.dart';
//
// class EpubRenderer {
//   late EpubContent content;
//
//   EpubRenderer(this.content);
//
//   Widget render() {
//     final document = parseHtmlContent(content.Html!);
//     applyCss(document, content.Css);
//     applyImage(document, content.Images);
//     applyFont(document, content.Fonts);
//     // write the document to a file
//     final file = File('/storage/emulated/0/Download/epub.html');
//     file.writeAsStringSync(document.outerHtml);
//     return buildWidgetTree(document);
//   }
//
//   html.Document parseHtmlContent(Map<String, EpubTextContentFile> htmlFiles) {
//     String htmlString = '';
//     htmlFiles.forEach((key, value) {
//       htmlString += value.Content!;
//     });
//     return parse(htmlString);
//   }
//
//   void applyCss(
//       html.Document document, Map<String, EpubTextContentFile>? cssFiles) {
//     String cssString = '';
//     cssFiles?.forEach((key, value) {
//       cssString += value.Content!;
//     });
//     document.head!.append(html.Element.tag('style')..text = cssString);
//   }
//
//   void applyImage(
//       html.Document document, Map<String, EpubByteContentFile>? imageFiles) {
//     imageFiles?.forEach((key, value) {
//       final dataUri = 'data:${value.ContentType};base64,${value.Content}';
//       document.body!
//           .append(html.Element.tag('img')..attributes['src'] = dataUri);
//     });
//   }
//
//   void applyFont(
//       html.Document document, Map<String, EpubByteContentFile>? fontFiles) {
//     fontFiles?.forEach((key, value) {
//       final dataUri = 'data:${value.ContentType};base64,${value.Content}';
//       document.head!.append(html.Element.tag('style')
//         ..text = '''
//         @font-face {
//           font-family: '$key';
//           src: url($dataUri);
//         }
//       ''');
//     });
//   }
//
//   Widget buildWidgetTree(html.Document document) {
//     return SingleChildScrollView(
//       child: Html(
//         data: document.outerHtml,
//       ),
//     );
//   }
// }
import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:archive/archive.dart';
import 'package:flutter/widgets.dart';

class EpubRenderer extends StatefulWidget {
  const EpubRenderer({super.key, required this.book});
  final Book book;

  @override
  State<EpubRenderer> createState() => _EpubRendererState();
}

class _EpubRendererState extends State<EpubRenderer> {
  
  @override
  void initState() {
    super.initState();
    Archive bookArchive = ZipDecoder().decodeBytes(File(widget.book.filePath).readAsBytesSync());
    for (ArchiveFile file in bookArchive) {
      print(file.name);
    }
    ArchiveFile chapter1 = bookArchive.firstWhere((file) => file.name == 'chapter1.html');
    print(chapter1.content);
  }
  
  @override
  Widget build(BuildContext context) {
    return const Placeholder();
  }
}
