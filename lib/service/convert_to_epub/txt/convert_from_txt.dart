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

  for (final line in lines) {
    if (line == '简介:' || line == '内容简介：' || line == '内容简介') {
      chapters.add('# $line \n');
      continue;
    }
    if (RegExp(r'^\s*(楔子|序章|序言|序|引子).*').hasMatch(line)) {
      chapters.add('## $line \n');
      continue;
    }
    if (RegExp(r'^\s*[第][0123456789ⅠI一二三四五六七八九十零序〇百千两]*[卷].*').hasMatch(line) ||
        RegExp(r'^\s*[卷][0123456789ⅠI一二三四五六七八九十零序〇百千两]*[ ].*').hasMatch(line)) {
      chapters.add('# $line \n');
      continue;
    }
    if (RegExp(r'^\s*[第][0123456789ⅠI一二三四五六七八九十零序〇百千两]*[章].*').hasMatch(line)) {
      chapters.add('## $line \n');
      continue;
    }

    chapters.isNotEmpty ? chapters.last += '$line \n' : chapters.add('$line\n');
  }

  final epubFile = await createEpub(titleString, authorString, chapters);

  return epubFile;
}
