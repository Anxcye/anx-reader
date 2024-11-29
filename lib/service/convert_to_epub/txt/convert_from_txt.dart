import 'dart:io';

import 'package:anx_reader/service/convert_to_epub/create_epub.dart';
import 'package:anx_reader/utils/log/common.dart';

Future<File> convertFromTxt(File file) async {
  var filename = file.path.split('/').last;

  filename = filename.split('.').first;
  final titleString =
      RegExp(r'(?<=《)[^》]+').firstMatch(filename)?.group(0) ?? filename;
  final authorString =
      RegExp(r'(?<=作者：).*').firstMatch(filename)?.group(0) ?? 'Unknown';

  AnxLog.info('convert from txt. title: $titleString, author: $authorString');

  // TODO: detect encoding and convert to utf-8

  // parse content
  final lines = file.readAsLinesSync();
  final chapters = <String>[];
  var level = 0;
  var orientation = false;

  final prologuePattern = RegExp(r'^\s*(楔子|序章|序言|序|引子).*');
  final volumePattern1 = RegExp(r'^\s*[第][0123456789ⅠI一二三四五六七八九十零序〇百千两]*[卷].*');
  final volumePattern2 = RegExp(r'^\s*[卷][0123456789ⅠI一二三四五六七八九十零序〇百千两]*[ ].*');
  final volumePattern3 = RegExp(r'^\s*(Vol(?:ume)?\.?|Book)\s*[0123456789ⅠI]*\s*[ ].*');

  final chapterPattern1 = RegExp(r'^\s*[第][0123456789ⅠI一二三四五六七八九十零序〇百千两]*[章].*');
  final chapterPattern2 = RegExp(r'^\s*(Chapter|Ch\.?)\s*[0123456789ⅠI]*\s*[ ].*');

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    if (!orientation) {
      if (line.startsWith('简介') || line.startsWith('内容简介')) {
        chapters.add('$line \n');
        continue;
      }

      if (prologuePattern.hasMatch(line)) {
        chapters.add('$line \n');
        continue;
      }
    }

    if (volumePattern1.hasMatch(line) ||
        volumePattern2.hasMatch(line) ||
        volumePattern3.hasMatch(line)) {
      orientation = true;
      level = 1;
      chapters.add('# $line \n');
      continue;
    }

    if (chapterPattern1.hasMatch(line) || chapterPattern2.hasMatch(line)) {
      orientation = true;
      chapters.add(level == 1 ? '## $line \n' : '# $line \n');
      continue;
    }

    chapters.isNotEmpty ? chapters.last += '$line \n' : chapters.add('$line\n');
  }

  final epubFile = await createEpub(titleString, authorString, chapters);

  return epubFile;
}
