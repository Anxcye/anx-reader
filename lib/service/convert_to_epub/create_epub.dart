import 'dart:io';

import 'package:anx_reader/service/convert_to_epub/generate_toc.dart';
import 'package:anx_reader/service/convert_to_epub/section.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:archive/archive_io.dart';
import 'package:uuid/uuid.dart';

String _escapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

Future<File> createEpub(
  String titleString,
  String authorString,
  // List<String> chapters,
  List<Section> sections,
) async {
  // create epub
  final cacheDir = await getAnxTempDir();
  final epubDir = Directory('${cacheDir.path}/anx_epub_${const Uuid().v4()}');
  epubDir.createSync();

  // mimetype
  final mimetypeFile = File('${epubDir.path}/mimetype');
  mimetypeFile.createSync();
  mimetypeFile.writeAsStringSync('application/epub+zip');

  // META-INF/container.xml
  final metainfDir = Directory('${epubDir.path}/META-INF');
  metainfDir.createSync();
  final containerFile = File('${epubDir.path}/META-INF/container.xml');
  containerFile.createSync();
  containerFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<container version="1.0" xmlns="urn:oasis:names:tc:opendocument:xmlns:container">
  <rootfiles>
    <rootfile full-path="OEBPS/content.opf" media-type="application/oebps-package+xml"/>
  </rootfiles>
</container>''');

  // OEBPS
  final oebpsDir = Directory('${epubDir.path}/OEBPS');
  oebpsDir.createSync();

  // content.opf
  final contentFile = File('${oebpsDir.path}/content.opf');
  contentFile.createSync();
  final manifestItems = List.generate(
          sections.length,
          (index) =>
              '    <item id="item$index" href="xhtml/$index.xhtml" media-type="application/xhtml+xml"/>')
      .join('\n');
  final spineItems = List.generate(
          sections.length, (index) => '    <itemref idref="item$index"/>')
      .join('\n');

  contentFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>${_escapeXml(titleString)}</dc:title>
    <dc:creator>${_escapeXml(authorString)}</dc:creator>
    <dc:identifier id="pub-id">urn:uuid:${const Uuid().v4()}</dc:identifier>
  </metadata>

  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="css" href="style.css" media-type="text/css"/>
    $manifestItems
  </manifest>

  <spine toc="ncx">
    $spineItems
  </spine>
</package>''');

  // toc.ncx
  final tocFile = File('${oebpsDir.path}/toc.ncx');
  tocFile.createSync();
  tocFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<ncx xmlns="http://www.daisy.org/z3986/2005/ncx/" version="2005-1" xml:lang="zh-CN">
  <head>
    <meta name="dtb:uid" content="urn:uuid:${const Uuid().v4()}"/>
    <meta name="dtb:depth" content="1"/>
    <meta name="dtb:totalPageCount" content="${sections.length}"/>
  </head>
  <docTitle>
    <text>${_escapeXml(titleString)}</text>
  </docTitle>
  <navMap>
    ${generateNestedToc(sections)}
  </navMap>
</ncx>''');

  // style.css
  final styleFile = File('${oebpsDir.path}/style.css');
  styleFile.createSync();
  styleFile.writeAsStringSync('''body {
  overflow-wrap: break-word;
  word-wrap: break-word;
}
pre {
  overflow-x: auto;
  white-space: pre-wrap;
  word-break: break-word;
}
code {
  font-family: monospace;
}
blockquote {
  border-left: 0.2em solid currentColor;
  margin-left: 0;
  padding-left: 1em;
}
.table-wrap {
  max-width: 100%;
  overflow-x: auto;
}
table {
  border-collapse: collapse;
  max-width: 100%;
}
th, td {
  border: 1px solid currentColor;
  padding: 0.35em 0.55em;
  text-align: left;
}
''');
  // xhtml
  final xhtmlDir = Directory('${oebpsDir.path}/xhtml');
  xhtmlDir.createSync();
  for (var i = 0; i < sections.length; i++) {
    final xhtmlFile = File('${xhtmlDir.path}/$i.xhtml');
    xhtmlFile.createSync();

    final rawTitle = sections[i].title.trim();
    final level = sections[i].level.clamp(1, 6);
    final content = sections[i].content;

    final heading = rawTitle.isEmpty
        ? ''
        : '    <h$level>${_escapeXml(rawTitle)}</h$level>';

    final paragraphLines = sections[i].xhtmlContent == null
        ? content
            .split('\n')
            .map((e) => e.trim())
            .where((line) => line.isNotEmpty)
            .map((line) => '    <p>${_escapeXml(line)}</p>')
            .toList()
        : <String>[];

    final bodyBuffer = StringBuffer();
    if (heading.isNotEmpty) {
      bodyBuffer.writeln(heading);
    }
    if (sections[i].xhtmlContent case final xhtml?) {
      bodyBuffer.writeln(xhtml);
    } else {
      for (final line in paragraphLines) {
        bodyBuffer.writeln(line);
      }
    }

    final bodyContent = bodyBuffer.toString().trimRight();

    xhtmlFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head>
    <title>${_escapeXml(rawTitle.isEmpty ? titleString : rawTitle)}</title>
    <link rel="stylesheet" type="text/css" href="../style.css" />
  </head>
  <body>
${bodyContent.isEmpty ? '' : '$bodyContent\n'}
  </body>
</html>''');
  }

  // zip
  final safeFileName =
      titleString.replaceAll(RegExp(r'[<>:"/\\|?*\x00-\x1F]'), '_').trim();
  final zipFile = File(
      '${cacheDir.path}/${safeFileName.isEmpty ? 'document' : safeFileName}.epub');
  zipFile.createSync();

  try {
    final encoder = ZipFileEncoder();
    encoder.create(zipFile.path);
    await encoder.addFile(mimetypeFile);
    await encoder.addDirectory(metainfDir);
    await encoder.addDirectory(oebpsDir);
    await encoder.close();
  } catch (e) {
    AnxLog.severe('EPUB: ZIP compression failed: $e');
    rethrow;
  }

  epubDir.deleteSync(recursive: true);
  return zipFile;
}
