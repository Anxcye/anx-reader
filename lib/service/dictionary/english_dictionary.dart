import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';

class EnglishDictionaryEntry {
  const EnglishDictionaryEntry({
    this.lemma,
    this.phonetic,
    this.audioUrl,
    this.partOfSpeech,
    this.definitionEn,
    this.exampleSentence,
  });

  final String? lemma;
  final String? phonetic;
  final String? audioUrl;
  final String? partOfSpeech;
  final String? definitionEn;
  final String? exampleSentence;

  bool get hasPronunciation =>
      (phonetic?.trim().isNotEmpty ?? false) ||
      (audioUrl?.trim().isNotEmpty ?? false);

  bool get hasContent =>
      hasPronunciation ||
      (lemma?.trim().isNotEmpty ?? false) ||
      (partOfSpeech?.trim().isNotEmpty ?? false) ||
      (definitionEn?.trim().isNotEmpty ?? false) ||
      (exampleSentence?.trim().isNotEmpty ?? false);

  Map<String, dynamic> toJson() {
    return {
      'lemma': lemma,
      'phonetic': phonetic,
      'audioUrl': audioUrl,
      'partOfSpeech': partOfSpeech,
      'definitionEn': definitionEn,
      'exampleSentence': exampleSentence,
      'updatedAt': DateTime.now().toIso8601String(),
    };
  }

  factory EnglishDictionaryEntry.fromJson(Map<String, dynamic> json) {
    return EnglishDictionaryEntry(
      lemma: _cleanString(json['lemma']),
      phonetic: _cleanString(json['phonetic']),
      audioUrl: _normalizeAudioUrl(_cleanString(json['audioUrl'])),
      partOfSpeech: _cleanString(json['partOfSpeech']),
      definitionEn: _cleanString(json['definitionEn']),
      exampleSentence: _cleanString(json['exampleSentence']),
    );
  }
}

class EnglishDictionaryService {
  EnglishDictionaryService._();

  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 6),
    ),
  );

  static final Map<String, EnglishDictionaryEntry?> _memoryCache = {};
  static const int _maxCacheSize = 1200;

  static bool isEnglishWord(String text) {
    return _normalizeLookupWord(text) != null;
  }

  static Future<EnglishDictionaryEntry?> lookup(String text) async {
    final word = _normalizeLookupWord(text);
    if (word == null) return null;

    if (_memoryCache.containsKey(word)) {
      return _memoryCache[word];
    }

    final cached = _readCached(word);
    if (cached != null) {
      _remember(word, cached);
      return cached;
    }

    try {
      final response = await _dio.get(
        'https://api.dictionaryapi.dev/api/v2/entries/en/${Uri.encodeComponent(word)}',
      );
      final entry = _parseResponse(response.data);
      _remember(word, entry);
      _writeCached(word, entry);
      return entry;
    } catch (e) {
      AnxLog.warning('English dictionary lookup failed for "$word": $e');
      return null;
    }
  }

  static EnglishDictionaryEntry? _parseResponse(dynamic data) {
    if (data is String) {
      data = jsonDecode(data);
    }
    if (data is! List || data.isEmpty) return null;

    String? phonetic;
    String? audioUrl;
    String? partOfSpeech;
    String? lemma;
    String? definitionEn;
    String? exampleSentence;

    for (final rawEntry in data) {
      if (rawEntry is! Map) continue;

      lemma ??= _cleanString(rawEntry['word']);
      phonetic ??= _normalizePhonetic(_cleanString(rawEntry['phonetic']));

      final phonetics = rawEntry['phonetics'];
      if (phonetics is List) {
        for (final rawPhonetic in phonetics) {
          if (rawPhonetic is! Map) continue;
          phonetic ??= _normalizePhonetic(_cleanString(rawPhonetic['text']));
          audioUrl ??= _normalizeAudioUrl(_cleanString(rawPhonetic['audio']));
          if (phonetic != null && audioUrl != null) break;
        }
      }

      final meanings = rawEntry['meanings'];
      if (meanings is List) {
        for (final rawMeaning in meanings) {
          if (rawMeaning is! Map) continue;
          partOfSpeech ??= _cleanString(rawMeaning['partOfSpeech']);
          final definitions = rawMeaning['definitions'];
          if (definitions is List) {
            for (final rawDefinition in definitions) {
              if (rawDefinition is! Map) continue;
              definitionEn ??= _cleanString(rawDefinition['definition']);
              exampleSentence ??= _cleanString(rawDefinition['example']);
              if (definitionEn != null && exampleSentence != null) {
                break;
              }
            }
          }
          if (partOfSpeech != null) break;
        }
      }

      if (phonetic != null &&
          audioUrl != null &&
          partOfSpeech != null &&
          definitionEn != null &&
          exampleSentence != null) {
        break;
      }
    }

    final entry = EnglishDictionaryEntry(
      lemma: lemma,
      phonetic: phonetic,
      audioUrl: audioUrl,
      partOfSpeech: partOfSpeech,
      definitionEn: definitionEn,
      exampleSentence: exampleSentence,
    );
    return entry.hasContent ? entry : null;
  }

  static void _remember(String word, EnglishDictionaryEntry? entry) {
    if (_memoryCache.length >= _maxCacheSize) {
      _memoryCache.remove(_memoryCache.keys.first);
    }
    _memoryCache[word] = entry;
  }

  static EnglishDictionaryEntry? _readCached(String word) {
    final raw = Prefs().prefs.getString(_cacheKey(word));
    if (raw == null || raw.isEmpty) return null;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is Map<String, dynamic>) {
        return EnglishDictionaryEntry.fromJson(decoded);
      }
      if (decoded is Map) {
        return EnglishDictionaryEntry.fromJson(
          decoded.map((key, value) => MapEntry(key.toString(), value)),
        );
      }
    } catch (e) {
      AnxLog.warning('Failed to decode English dictionary cache: $e');
    }
    return null;
  }

  static void _writeCached(String word, EnglishDictionaryEntry? entry) {
    if (entry == null) return;
    Prefs().prefs.setString(_cacheKey(word), jsonEncode(entry.toJson()));
  }

  static String _cacheKey(String word) {
    return 'englishDictionaryEntry_$word';
  }

  static String? _normalizeLookupWord(String text) {
    final word = text
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r"^[^a-z]+|[^a-z'-]+$", caseSensitive: false), '');
    if (!RegExp(r"^[a-z][a-z'-]{0,63}$").hasMatch(word)) return null;
    return word;
  }
}

String? _cleanString(dynamic value) {
  final text = value?.toString().trim();
  return text == null || text.isEmpty ? null : text;
}

String? _normalizePhonetic(String? value) {
  if (value == null) return null;
  final text = value.trim();
  if (text.isEmpty) return null;
  if (text.startsWith('/') || text.startsWith('[')) return text;
  return '/$text/';
}

String? _normalizeAudioUrl(String? value) {
  if (value == null || value.isEmpty) return null;
  if (value.startsWith('//')) return 'https:$value';
  return value;
}
