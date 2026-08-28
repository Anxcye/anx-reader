import 'dart:collection';
import 'dart:convert';

import 'package:archive/archive.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class ChineseDictionarySense {
  const ChineseDictionarySense({required this.definition, this.example});

  final String definition;
  final String? example;
}

class ChineseDictionaryEntry {
  const ChineseDictionaryEntry({
    required this.word,
    required this.senses,
    this.pinyin,
  });

  final String word;
  final String? pinyin;
  final List<ChineseDictionarySense> senses;

  factory ChineseDictionaryEntry.fromJson(Map<String, dynamic> json) {
    final rawSenses = json['s'];
    return ChineseDictionaryEntry(
      word: json['w']?.toString() ?? '',
      pinyin: json['p']?.toString(),
      senses: rawSenses is List
          ? rawSenses
              .whereType<Map>()
              .map(
                (sense) => ChineseDictionarySense(
                  definition: sense['d']?.toString() ?? '',
                  example: sense['e']?.toString(),
                ),
              )
              .where((sense) => sense.definition.isNotEmpty)
              .toList(growable: false)
          : const [],
    );
  }
}

class ChineseWordBoundary {
  const ChineseWordBoundary({
    required this.word,
    required this.startOffset,
    required this.endOffset,
  });

  final String word;
  final int startOffset;
  final int endOffset;
}

class ChineseDictionaryService {
  ChineseDictionaryService._();

  static const _assetRoot = 'assets/dictionaries/chinese';
  static const _maxLoadedBuckets = 8;
  static const _maxBoundaryLength = 8;
  static final LinkedHashMap<String, Map<String, ChineseDictionaryEntry>>
      _bucketCache = LinkedHashMap();

  static bool isChineseText(String text) {
    final value = text.trim();
    return value.isNotEmpty &&
        value.runes.every((rune) =>
            (rune >= 0x3400 && rune <= 0x4dbf) ||
            (rune >= 0x4e00 && rune <= 0x9fff) ||
            (rune >= 0xf900 && rune <= 0xfaff));
  }

  static bool isLookupCandidate(String text) {
    final value = text.trim();
    return isChineseText(value) && value.runes.length <= _maxBoundaryLength;
  }

  static Future<ChineseDictionaryEntry?> lookup(
    String selection, {
    String? contextText,
  }) async {
    final selected = selection.trim();
    if (!isLookupCandidate(selected)) return null;

    final exact = await _lookupExact(selected);
    if (selected.runes.length > 1 && exact != null) return exact;

    final candidates = _boundaryCandidates(selected, contextText);
    for (final candidate in candidates) {
      final entry = await _lookupExact(candidate);
      if (entry != null) return entry;
    }
    return exact;
  }

  static Future<ChineseWordBoundary> resolveBoundary(
    String text,
    int offset,
  ) async {
    if (text.isEmpty) {
      return const ChineseWordBoundary(word: '', startOffset: 0, endOffset: 0);
    }
    final safeOffset = offset.clamp(0, text.length - 1);
    final candidates = <ChineseWordBoundary>[];
    final maxLength =
        text.length < _maxBoundaryLength ? text.length : _maxBoundaryLength;
    for (var length = maxLength; length >= 1; length--) {
      final minStart = (safeOffset - length + 1).clamp(0, text.length);
      final maxStart = safeOffset.clamp(0, text.length - length);
      for (var start = minStart; start <= maxStart; start++) {
        final end = start + length;
        if (end > text.length || safeOffset >= end) continue;
        final word = text.substring(start, end);
        if (isChineseText(word)) {
          candidates.add(ChineseWordBoundary(
            word: word,
            startOffset: start,
            endOffset: end,
          ));
        }
      }
    }
    for (final candidate in candidates) {
      if (await _lookupExact(candidate.word) != null) return candidate;
    }
    final fallback = text.substring(safeOffset, safeOffset + 1);
    return ChineseWordBoundary(
      word: fallback,
      startOffset: safeOffset,
      endOffset: safeOffset + 1,
    );
  }

  static Future<ChineseDictionaryEntry?> _lookupExact(String word) async {
    if (word.isEmpty) return null;
    final bucketName =
        (word.runes.first >> 8).toRadixString(16).padLeft(2, '0');
    final bucket = await _loadBucket(bucketName);
    return bucket[word];
  }

  static Future<Map<String, ChineseDictionaryEntry>> _loadBucket(
    String name,
  ) async {
    final cached = _bucketCache.remove(name);
    if (cached != null) {
      _bucketCache[name] = cached;
      return cached;
    }

    try {
      final data = await rootBundle.load('$_assetRoot/$name.json.gz');
      final decoded = await compute(
        _decodeChineseDictionaryBucket,
        data.buffer.asUint8List(),
      );
      final bucket = <String, ChineseDictionaryEntry>{};
      for (final item in decoded.entries) {
        if (item.value is Map) {
          bucket[item.key] = ChineseDictionaryEntry.fromJson(
            Map<String, dynamic>.from(item.value as Map),
          );
        }
      }
      _bucketCache[name] = bucket;
      if (_bucketCache.length > _maxLoadedBuckets) {
        _bucketCache.remove(_bucketCache.keys.first);
      }
      return bucket;
    } catch (_) {
      return const {};
    }
  }

  static List<String> _boundaryCandidates(
    String selection,
    String? contextText,
  ) {
    final context = contextText?.trim() ?? '';
    if (context.isEmpty || !context.contains(selection)) return const [];

    final candidates = <String>{};
    var match = context.indexOf(selection);
    while (match >= 0) {
      final before = context.substring(0, match).runes.toList();
      final selectedRunes = selection.runes.toList();
      final after = context.substring(match + selection.length).runes.toList();
      for (var left = 0;
          left <= before.length && left < _maxBoundaryLength;
          left++) {
        for (var right = 0;
            right <= after.length &&
                left + selectedRunes.length + right <= _maxBoundaryLength;
            right++) {
          final runes = <int>[
            ...before.skip(before.length - left),
            ...selectedRunes,
            ...after.take(right),
          ];
          final candidate = String.fromCharCodes(runes);
          if (candidate != selection && isChineseText(candidate)) {
            candidates.add(candidate);
          }
        }
      }
      match = context.indexOf(selection, match + selection.length);
    }
    final sorted = candidates.toList();
    sorted.sort((a, b) => b.runes.length.compareTo(a.runes.length));
    return sorted;
  }
}

Map<String, dynamic> _decodeChineseDictionaryBucket(Uint8List bytes) {
  final uncompressed = GZipDecoder().decodeBytes(bytes);
  return Map<String, dynamic>.from(
    jsonDecode(utf8.decode(uncompressed)) as Map,
  );
}
