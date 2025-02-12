import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/service/convert_to_epub/create_epub.dart';
import 'package:anx_reader/service/convert_to_epub/section.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:fast_gbk/fast_gbk.dart';

String readFileWithEncoding(File file) {
  bool checkGarbled(String content) {
    final garbledPattern = RegExp(r'[¡-ÿ]{2,}|[²-º]|Õ|Ê|Ç|³|¾|Ð|Ó|Î|Á|É|�');

    final lines = content.split('\n');

    final sampleLines = lines.take(lines.length > 10 ? 10 : lines.length);
    return sampleLines.any((line) => garbledPattern.hasMatch(line));
  }

  final List<Encoding> encodings = [
    utf8,
    latin1,
  ];

  for (final encoding in encodings) {
    try {
      AnxLog.info('Convert: Reading file with encoding: ${encoding.name}');
      final content = file.readAsStringSync(encoding: encoding);

      if (!checkGarbled(content)) {
        return content;
      }
      AnxLog.info('Convert: Detected garbled text, trying next encoding');
    } catch (e) {
      continue;
    }
  }

  try {
    AnxLog.info('Convert: Reading file with encoding: gbk');
    final content = gbk.decode(file.readAsBytesSync());
    return content;
  } catch (e) {
    AnxLog.severe('Convert: Failed to read file with encoding');
    return '';
  }
}

Future<File> convertFromTxt(File file) async {
  var filename = file.path.split('/').last;

  filename = filename.split('.').first;
  final titleString =
      RegExp(r'(?<=《)[^》]+').firstMatch(filename)?.group(0) ?? filename;
  final authorString =
      RegExp(r'(?<=作者：).*').firstMatch(filename)?.group(0) ?? 'Unknown';

  AnxLog.info('convert from txt. title: $titleString, author: $authorString');

  // read file
  String content = readFileWithEncoding(file);

  // content = content.replaceAll(RegExp(r'(\n*|^)(\s|　)+'), '\n');

  AnxLog.info('convert from txt. content: ${content.length}');

  final patternStr = RegExp(
    r'^(.* +|　*)?([第][一二三四五六七八九十零〇百千万两0123456789]+[章卷]|[卷][一二三四五六七八九十零〇百千万两0123456789]+|[Cc]hap(?:ter)\.?|[Vv]ol(?:ume)?\.?|[Bb]ook|[Bb]k)( +.*)?$',
    multiLine: true,
  );

  final matches = patternStr.allMatches(content).toList();
  final sections = <Section>[];

  AnxLog.info('matches: ${matches.length}');

  if (matches.isEmpty) {
    return createEpub(titleString, authorString, ['#$content}']);
  }

  if (matches.first.start > 0) {
    sections.add(Section('', content.substring(0, matches.first.start), 0));
  }

  for (int i = 0; i < matches.length; i++) {
    final match = matches[i];
    final title = match.group(0)!;

    final startPos = match.start;
    final endPos =
        i < matches.length - 1 ? matches[i + 1].start : content.length;

    final fullContent = content.substring(startPos, endPos);
    final contentWithoutTitle = fullContent.substring(title.length).trim();

    final volumeKeyword = ['卷', 'Book', 'bk', 'Vol'];
    final level =
        volumeKeyword.any((keyword) => title.contains(keyword)) ? 1 : 2;

    sections.add(Section(title.trim(), contentWithoutTitle.trim(), level));
  }

  final volumes = sections.map((section) {
    return section.toString();
  }).toList();

  final epubFile = await createEpub(titleString, authorString, volumes);
  return epubFile;
}
