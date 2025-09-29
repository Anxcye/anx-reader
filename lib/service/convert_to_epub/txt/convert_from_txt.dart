import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/models/chapter_split_presets.dart';
import 'package:anx_reader/service/convert_to_epub/create_epub.dart';
import 'package:anx_reader/service/convert_to_epub/section.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:charset/charset.dart';

String readFileWithEncoding(File file) {
  bool checkGarbled(String content) {
    final garbledPattern = RegExp(
        r'Õ|Ê|�|Ç|³|¾|Ð|Ó|Î|Á|É|�|Ã|Ä|Å|Æ|Ë|Ì|Í|Ï|Ò|Ó|Ô|Õ|Ö|Ù|Ú|Û|Ü|Ý|à|á|â|ã|ä|å|æ|è|é|ê|ë|ì|í|î|ï|ð|ñ|ò|ó|ô|õ|ö|ù|ú|û|ü|ý|ÿ|\x00-\x1F\x7F|｡｢｣､･ｦｧｨｩｪｫｬｭｮｯｰｱｲｳｴｵｶｷｸｹｺｻｼｽｾｿﾀﾁﾂﾃﾄﾅﾆﾇﾈﾉﾊﾋﾌﾍﾎﾏﾐﾑﾒﾓﾔﾕﾖﾗﾘﾙﾚﾛﾜﾝ|€|�');
    final sampleContent =
        content.length > 500 ? content.substring(0, 500) : content;

    final matches = garbledPattern.allMatches(sampleContent);

    final garbledCount = matches.length;

    return garbledCount / sampleContent.length > 20 / 500;
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

String _normalizeLineBreaks(String input) {
  return input.replaceAll('\r\n', '\n').replaceAll('\r', '\n');
}

int _inferSectionLevel(String title) {
  final simplified = title.replaceAll(RegExp(r'[\s\u3000]+'), ' ').trim();

  final hasVolumeKeyword = RegExp(
    r'(卷|部|篇|册|合集|季|part|volume|vol\.?|book\b)',
    caseSensitive: false,
  ).hasMatch(simplified);

  if (hasVolumeKeyword) {
    return 1;
  }

  final hasChapterKeyword = RegExp(
    r'(章|节|回|话|折|集|章回|chapter|chap\b|episode|section|\bch\b)',
    caseSensitive: false,
  ).hasMatch(simplified);

  if (hasChapterKeyword) {
    return 2;
  }

  final prologueKeyword = RegExp(r'(序|序章|序言|前言|楔子|引子)', caseSensitive: false);
  if (prologueKeyword.hasMatch(simplified)) {
    return 1;
  }

  return 2;
}

List<Section> _buildSectionsFromMatches({
  required String content,
  required List<RegExpMatch> matches,
  required String fallbackTitle,
}) {
  final sections = <Section>[];

  final firstMatch = matches.first;
  if (firstMatch.start > 0) {
    final intro = content.substring(0, firstMatch.start).trim();
    if (intro.isNotEmpty) {
      sections.add(Section('', intro, 1));
    }
  }

  for (var i = 0; i < matches.length; i++) {
    final match = matches[i];
    final title = match.group(0)?.trim() ?? 'Chapter ${i + 1}';

    final startPos = match.end;
    final endPos =
        i < matches.length - 1 ? matches[i + 1].start : content.length;

    final rawBody = content.substring(startPos, endPos);
    final body = rawBody.trim();

    final level = _inferSectionLevel(title);

    sections.add(Section(title, body, level));
  }

  if (sections.isEmpty) {
    sections.add(Section(fallbackTitle, content.trim(), 2));
  }

  return sections;
}

List<Section> _fallbackChunking(String filename, String content) {
  final sections = <Section>[];
  if (content.length <= 20000) {
    sections.add(Section(filename, content.trim(), 2));
    return sections;
  }

  var startIndex = 0;
  while (startIndex < content.length) {
    final endIndex = startIndex + 20000;
    if (endIndex >= content.length) {
      sections.add(Section('No.${sections.length + 1}',
          content.substring(startIndex).trim(), 2));
      break;
    }

    final nextNewline = content.indexOf('\n', endIndex);
    final chapterEndIndex = nextNewline == -1 ? content.length : nextNewline;

    sections.add(Section('No.${sections.length + 1}',
        content.substring(startIndex, chapterEndIndex).trim(), 2));
    startIndex = chapterEndIndex + 1;
  }

  return sections;
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
  content = _normalizeLineBreaks(content);

  // content = content.replaceAll(RegExp(r'(\n*|^)(\s|　)+'), '\n');

  AnxLog.info('convert from txt. content: ${content.length}');

  final rule = Prefs().activeChapterSplitRule;
  RegExp patternStr;
  try {
    patternStr = rule.buildRegExp();
  } catch (error) {
    AnxLog.warning(
        'Convert: Invalid chapter split rule ${rule.name}, using default. $error');
    patternStr = getDefaultChapterSplitRule().buildRegExp();
  }

  final matches = patternStr.allMatches(content).toList();
  AnxLog.info('matches: ${matches.length}');

  List<Section> sections;
  if (matches.isEmpty) {
    sections = _fallbackChunking(filename, content);
  } else {
    sections = _buildSectionsFromMatches(
      content: content,
      matches: matches,
      fallbackTitle: filename,
    );
  }
  final epubFile = await createEpub(titleString, authorString, sections);
  return epubFile;
}
