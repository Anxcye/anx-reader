import 'dart:io';

import 'package:anx_reader/service/convert_to_epub/generate_toc.dart';
import 'package:anx_reader/service/convert_to_epub/section.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:archive/archive_io.dart';
import 'package:uuid/uuid.dart';

Future<File> createEpub(
  String titleString,
  String authorString,
  // List<String> chapters,
  List<Section> sections,
) async {
  // create epub
  final cacheDir = await getAnxTempDir();
  final epubDir = Directory('${cacheDir.path}/$titleString');
  if (epubDir.existsSync()) {
    epubDir.deleteSync(recursive: true);
  }
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
  contentFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<package xmlns="http://www.idpf.org/2007/opf" version="3.0" unique-identifier="pub-id">
  <metadata xmlns:dc="http://purl.org/dc/elements/1.1/">
    <dc:title>$titleString</dc:title>
    <dc:creator>$authorString</dc:creator>
    <dc:identifier id="pub-id">urn:uuid:${const Uuid().v4()}</dc:identifier>
  </metadata>

  <manifest>
    <item id="ncx" href="toc.ncx" media-type="application/x-dtbncx+xml"/>
    <item id="css" href="style.css" media-type="text/css"/>
    ${sections.map((e) => '    <item id="${sections.indexOf(e)}" href="xhtml/${sections.indexOf(e)}.xhtml" media-type="application/xhtml+xml"/>').join('\n')}
  </manifest>

  <spine toc="ncx">
    ${sections.map((e) => '    <itemref idref="${sections.indexOf(e)}"/>').join('\n')}
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
    <text>$titleString</text>
  </docTitle>
  <navMap>
    ${generateNestedToc(sections)}
  </navMap>
</ncx>''');

  // style.css
  final styleFile = File('${oebpsDir.path}/style.css');
  styleFile.createSync();
  styleFile.writeAsStringSync('''body {

}
''');
  // xhtml
  final xhtmlDir = Directory('${oebpsDir.path}/xhtml');
  xhtmlDir.createSync();
  for (var i = 0; i < sections.length; i++) {
    final xhtmlFile = File('${xhtmlDir.path}/$i.xhtml');
    xhtmlFile.createSync();

    final title = sections[i].title;
    final level = sections[i].level;
    final content = sections[i].content;

    xhtmlFile.writeAsStringSync('''<?xml version="1.0" encoding="utf-8"?>
<html xmlns="http://www.w3.org/1999/xhtml" xmlns:epub="http://www.idpf.org/2007/ops">
  <head>
    <title>$title</title>
  </head>
  <body>
    <h$level>$title</h$level>
    ${content.split('\n').map((e) => e.trim().isNotEmpty ? '<p>${e.trim()}</p>' : '').join('\n')}
  </body>
</html>''');
  }

  // zip
  final zipFile = File('${cacheDir.path}/$titleString.epub');
  zipFile.createSync();
  final encoder = ZipFileEncoder();
  encoder.create(zipFile.path);
  await encoder.addFile(mimetypeFile);
  await encoder.addDirectory(metainfDir);
  await encoder.addDirectory(oebpsDir);
  await encoder.close();

  epubDir.deleteSync(recursive: true);

  return zipFile;
}
