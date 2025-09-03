import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/service/convert_to_epub/create_epub.dart';
import 'package:anx_reader/service/convert_to_epub/section.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:charset/charset.dart';

String readFileWithEncoding(File file) {
  bool checkGarbled(String content) {
    final garbledPattern = RegExp(r'Õ|Ê|�|Ç|³|¾|Ð|Ó|Î|Á|É|�|Ã|Ä|Å|Æ|Ë|Ì|Í|Ï|Ò|Ó|Ô|Õ|Ö|Ù|Ú|Û|Ü|Ý|à|á|â|ã|ä|å|æ|è|é|ê|ë|ì|í|î|ï|ð|ñ|ò|ó|ô|õ|ö|ù|ú|û|ü|ý|ÿ|\x00-\x1F\x7F|｡｢｣､･ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ|€|�');
    final sampleContent = content.length > 500 
        ? content.substring(0, 500) 
        : content;

    final matches = garbledPattern.allMatches(sampleContent);
    
    final garbledCount = matches.length;

    return garbledCount / sampleContent.length  > 20 / 500;
  }

  final decoder = {
    'utf8': utf8.decode,
    'gbk': gbk.decode,
    'latin1': latin1.decode,
    'utf16': utf16.decode,
    'utf32': utf32.decode,
  };

  for (final entry in decoder.entries) {
    try {
      AnxLog.info('Convert: Reading file with encoding: ${entry.key}');
      final content = entry.value(file.readAsBytesSync());
      if (!checkGarbled(content)) {
        return content;
      }
      AnxLog.info('Convert: Detected garbled text ${entry.key}');
    } catch (e) {
      AnxLog.warning(
          'Convert: Failed to read file with encoding: ${entry.key}');
    }
  }

  throw Exception('Convert: Failed to read file with any encoding');
}

Future<File> convertFromTxt(File file) async {
  var filename = file.path.split('/').last;

  filename =
      filename.split('.').sublist(0, filename.split('.').length - 1).join('.');
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
    r'^(?:(.+ +)|())(第[一二三四五六七八九十零〇百千万两0123456789]+[章卷]|卷[一二三四五六七八九十零〇百千万两0123456789]+|chap(?:ter)\.?|vol(?:ume)?\.?|book|bk)(?:(?: +.+)?|(?:\S.*)?)$',
    multiLine: true,
    caseSensitive: false,
  );

  final matches = patternStr.allMatches(content).toList();
  final sections = <Section>[];

  AnxLog.info('matches: ${matches.length}');

  if (matches.isEmpty) {
    final newSections = <Section>[];

    if (content.length <= 20000) {
      newSections.add(Section(filename, content, 2));
      return createEpub(titleString, authorString, newSections);
    } else {
      var startIndex = 0;
      while (startIndex < content.length) {
        final endIndex = startIndex + 20000;
        if (endIndex >= content.length) {
          newSections.add(Section('No.${newSections.length + 1}',
              content.substring(startIndex), 2));
          break;
        }

        final nextNewline = content.indexOf('\n', endIndex);
        final chapterEndIndex =
            nextNewline == -1 ? content.length : nextNewline;

        newSections.add(Section('No.${newSections.length + 1}',
            content.substring(startIndex, chapterEndIndex), 2));
        startIndex = chapterEndIndex + 1;
      }
      return createEpub(titleString, authorString, newSections);
    }
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
    final chapterKeyword = ['章', 'Chapter', 'chap', 'Ch'];
    final level = chapterKeyword.any((keyword) => title.contains(keyword))
        ? 2
        : volumeKeyword.any((keyword) => title.contains(keyword))
            ? 1
            : 0;

    sections.add(Section(title.trim(), contentWithoutTitle.trim(), level));
  }

  final epubFile = await createEpub(titleString, authorString, sections);
  return epubFile;
}
