import 'dart:convert';
import 'dart:io';
import 'dart:isolate';

import 'package:anx_reader/service/convert_to_epub/create_epub.dart';
import 'package:anx_reader/utils/log/common.dart';

import 'package:flutter_gbk2utf8/flutter_gbk2utf8.dart';

List<String> readFileWithEncoding(File file) {
  bool checkGarbled(List<String> lines) {
    final garbledPattern = RegExp(r'[¡-ÿ]{2,}|[²-º]|Õ|Ê|Ç|³|¾|Ð|Ó|Î|Á|É');

    final sampleLines = lines.take(10);
    return sampleLines.any((line) => garbledPattern.hasMatch(line));
  }

  final List<Encoding> encodings = [
    utf8,
    latin1,
  ];

  for (final encoding in encodings) {
    try {
      AnxLog.info('Convert: Reading file with encoding: ${encoding.name}');
      final lines = file.readAsLinesSync(encoding: encoding);

      if (!checkGarbled(lines)) {
        return lines;
      }
      AnxLog.info('Convert: Detected garbled text, trying next encoding');
    } catch (e) {
      continue;
    }
  }

  try {
    AnxLog.info('Convert: Reading file with encoding: gbk');
    final content = gbk.decode(file.readAsBytesSync());
    return content.split('\n');
  } catch (e) {
    AnxLog.severe('Convert: Failed to read file with encoding');
    return [];
  }
}

Future<List<String>> processChunkInIsolate(Map<String, dynamic> params) async {
  final List<String> lines = params['lines'];
  final chapters = <String>[];
  var orientation = params['orientation'];
  var currentChapter = StringBuffer();

  final prologuePattern = RegExp(r'^\s*(楔子|序章|序言|序|引子).*');
  final volumePattern = RegExp(
      r'^\s*(?:[第][0123456789ⅠI一二三四五六七八九十零序〇百千两]*[卷]|[卷][0123456789ⅠI一二三四五六七八九十零序〇百千两]*[ ]|(Vol(?:ume)?\.?|Book)\s*[0123456789ⅠI]*\s*[ ]).*');
  final chapterPattern = RegExp(
      r'^\s*(?:[第][0123456789ⅠI一二三四五六七八九十零序〇百千两]*[章]|(Chapter|Ch\.?)\s*[0123456789ⅠI]*\s*[ ]).*');

  void addChapter() {
    if (currentChapter.isNotEmpty) {
      chapters.add(currentChapter.toString());
      currentChapter.clear();
    }
  }

  for (var line in lines) {
    line = line.trim();
    if (line.isEmpty) continue;

    if (!orientation) {
      if (line.startsWith('简介') || line.startsWith('内容简介')) {
        addChapter();
        currentChapter.writeln('## $line');
        continue;
      }

      if (prologuePattern.hasMatch(line)) {
        addChapter();
        currentChapter.writeln('## $line');
        continue;
      }
    }

    if (volumePattern.hasMatch(line)) {
      orientation = true;
      addChapter();
      currentChapter.writeln('# $line');
      continue;
    }

    if (chapterPattern.hasMatch(line)) {
      orientation = true;
      addChapter();
      currentChapter.writeln('## $line');
      continue;
    }

    currentChapter.writeln(line);
  }

  addChapter();
  return chapters;
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
  final lines = readFileWithEncoding(file);

  // split file to chunks
  final int chunkSize = (lines.length / Platform.numberOfProcessors).ceil();
  final chunks = <List<String>>[];

  for (var i = 0; i < lines.length; i += chunkSize) {
    chunks.add(lines.sublist(
        i, i + chunkSize > lines.length ? lines.length : i + chunkSize));
  }

  // process each chunk in parallel
  final futures = chunks.map((chunk) {
    return Isolate.run(() => processChunkInIsolate({
          'lines': chunk,
          'orientation': false,
        }));
  }).toList();

  final results = await Future.wait(futures);
  List chapters = results.expand((x) => x).toList();
  List<String> chaptersAfterRearrange = [];

  // if some String not begin with '#' or '##',  concat them after previous one
  for (var chapter in chapters) {
    if (chapter.startsWith('#') || chapter.startsWith('##')) {
      chaptersAfterRearrange.add(chapter);
    } else {
      chaptersAfterRearrange.isNotEmpty
          ? chaptersAfterRearrange.last +=chapter
          : chaptersAfterRearrange.add(chapter);
    }
  }

  final epubFile =
      await createEpub(titleString, authorString, chaptersAfterRearrange);
  return epubFile;
}
