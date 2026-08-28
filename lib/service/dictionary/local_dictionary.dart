import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/dictionary/word_morphology.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:dict_reader/dict_reader.dart';
import 'package:path/path.dart' as path;

class LocalDictionaryMatch {
  const LocalDictionaryMatch({
    required this.word,
    required this.dictionaryName,
    required this.html,
  });

  final String word;
  final String dictionaryName;
  final String html;
}

class LocalDictionaryService {
  LocalDictionaryService._();

  static const _prefsKey = 'localMdxDictionaries';
  static final Map<String, Future<DictReader>> _readers = {};

  static List<String> get dictionaryPaths =>
      Prefs().prefs.getStringList(_prefsKey) ?? const [];

  static Future<String> importMdx(String sourcePath) async {
    final source = File(sourcePath);
    if (!await source.exists() ||
        path.extension(sourcePath).toLowerCase() != '.mdx') {
      throw const FormatException('Invalid MDX file');
    }
    final root = await getAnxDocumentDir();
    final directory = Directory(path.join(root.path, 'dictionaries'));
    await directory.create(recursive: true);
    final target = path.join(directory.path, path.basename(sourcePath));
    await source.copy(target);

    final paths = [...dictionaryPaths.where((item) => item != target), target];
    await Prefs().prefs.setStringList(_prefsKey, paths);
    return target;
  }

  static Future<void> remove(String dictionaryPath) async {
    _readers.remove(dictionaryPath);
    final paths =
        dictionaryPaths.where((item) => item != dictionaryPath).toList();
    await Prefs().prefs.setStringList(_prefsKey, paths);
    final file = File(dictionaryPath);
    if (await file.exists()) await file.delete();
  }

  static Future<LocalDictionaryMatch?> lookup(String text) async {
    final value = text.trim();
    final isEnglishWord = RegExp(r"^[a-zA-Z][a-zA-Z'-]{0,63}$").hasMatch(value);
    final isChineseWord = value.isNotEmpty &&
        value.runes.length <= 8 &&
        value.runes.every((rune) => rune >= 0x3400 && rune <= 0x9fff);
    if (!isEnglishWord && !isChineseWord) return null;
    final candidates = WordMorphology.englishLemmas(text).toList();
    if (candidates.isEmpty) candidates.add(text.trim());
    for (final dictionaryPath in dictionaryPaths.reversed) {
      if (!await File(dictionaryPath).exists()) continue;
      try {
        final reader = await _reader(dictionaryPath);
        for (final candidate in candidates) {
          final offset = await reader.locate(candidate);
          if (offset == null) continue;
          return LocalDictionaryMatch(
            word: candidate,
            dictionaryName: path.basenameWithoutExtension(dictionaryPath),
            html: await reader.readOneMdx(offset),
          );
        }
      } catch (_) {
        continue;
      }
    }
    return null;
  }

  static Future<DictReader> _reader(String dictionaryPath) {
    return _readers.putIfAbsent(dictionaryPath, () async {
      final reader = DictReader(dictionaryPath);
      await reader.initDict();
      return reader;
    });
  }
}
