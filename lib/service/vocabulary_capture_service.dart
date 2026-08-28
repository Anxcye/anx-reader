import 'dart:async';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/vocabulary.dart';
import 'package:anx_reader/models/vocabulary_item.dart';
import 'package:anx_reader/service/dictionary/english_dictionary.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:uuid/uuid.dart';

typedef VocabularyTranslationLookup = Future<String> Function(
  String text, {
  String? contextText,
});

class VocabularyCaptureResult {
  const VocabularyCaptureResult({
    required this.item,
    required this.created,
    required this.updated,
  });

  final VocabularyItem item;
  final bool created;
  final bool updated;
}

class VocabularyCaptureService {
  VocabularyCaptureService._();

  static final Map<String, _VocabularyCaptureDraft> _draftCache = {};
  static final Map<String, Future<_VocabularyCaptureDraft?>> _draftTasks = {};
  static const int _maxDraftCacheSize = 200;

  static Future<VocabularyCaptureResult> captureQuick({
    required String word,
    required String bookId,
    String? bookTitle,
    String? chapterId,
    String? chapterTitle,
    String? contextText,
    String? position,
    VocabularyTranslationLookup? translateLookup,
    Future<EnglishDictionaryEntry?> Function(String word)? dictionaryLookup,
    String? translateToCode,
    DateTime? now,
  }) async {
    final trimmedWord = word.trim();
    if (trimmedWord.isEmpty) {
      throw ArgumentError('word must not be empty');
    }

    final currentTime = now ?? DateTime.now();
    final effectiveContextText = _normalizeOptionalText(contextText);
    final sourceSentence = extractSourceSentence(
      trimmedWord,
      effectiveContextText,
    );
    final contextWindow = extractContextWindow(
      trimmedWord,
      effectiveContextText,
      sourceSentence,
    );
    final resolvedTranslateToCode = translateToCode ?? Prefs().translateTo.code;
    final existing = await vocabularyDao.selectByWord(trimmedWord);
    final draftKey = _draftCacheKey(
      word: trimmedWord,
      contextText: effectiveContextText,
      translateToCode: resolvedTranslateToCode,
    );
    final cachedDraft = _draftCache[draftKey];
    final baseItem = _composeItem(
      existing: existing,
      word: trimmedWord,
      bookId: bookId,
      bookTitle: bookTitle,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      sourceSentence: cachedDraft?.sourceSentence ?? sourceSentence,
      sourceSentenceTranslation: cachedDraft?.sourceSentenceTranslation,
      contextualDefinition: cachedDraft?.contextualDefinition,
      contextBefore: cachedDraft?.contextBefore ?? contextWindow.before,
      contextAfter: cachedDraft?.contextAfter ?? contextWindow.after,
      position: position,
      dictionaryEntry: cachedDraft?.dictionaryEntry,
      translateToCode: resolvedTranslateToCode,
      now: currentTime,
    );

    final result =
        await _persistComposedItem(existing: existing, item: baseItem);
    if (cachedDraft == null) {
      unawaited(
        _enrichStoredItem(
          existing: result.item,
          translateLookup: translateLookup ?? translateTextOnly,
          dictionaryLookup: dictionaryLookup ?? EnglishDictionaryService.lookup,
          translateToCode: resolvedTranslateToCode,
        ),
      );
    }
    return result;
  }

  static void warmCaptureData({
    required String word,
    String? contextText,
    VocabularyTranslationLookup? translateLookup,
    Future<EnglishDictionaryEntry?> Function(String word)? dictionaryLookup,
    String? translateToCode,
  }) {
    final trimmedWord = word.trim();
    if (trimmedWord.isEmpty) return;

    final effectiveContextText = _normalizeOptionalText(contextText);
    final resolvedTranslateToCode = translateToCode ?? Prefs().translateTo.code;
    final key = _draftCacheKey(
      word: trimmedWord,
      contextText: effectiveContextText,
      translateToCode: resolvedTranslateToCode,
    );

    if (_draftCache.containsKey(key) || _draftTasks.containsKey(key)) {
      return;
    }

    final task = _buildDraft(
      word: trimmedWord,
      contextText: effectiveContextText,
      translator: translateLookup ?? translateTextOnly,
      lookupDictionary: dictionaryLookup ?? EnglishDictionaryService.lookup,
    );
    _draftTasks[key] = task;
    unawaited(() async {
      try {
        final draft = await task;
        if (draft != null) {
          _rememberDraft(key, draft);
        }
      } finally {
        _draftTasks.remove(key);
      }
    }());
  }

  static Future<VocabularyCaptureResult> capture({
    required String word,
    required String bookId,
    String? bookTitle,
    String? chapterId,
    String? chapterTitle,
    String? contextText,
    String? position,
    VocabularyTranslationLookup? translateLookup,
    Future<EnglishDictionaryEntry?> Function(String word)? dictionaryLookup,
    String? translateToCode,
    DateTime? now,
  }) async {
    final trimmedWord = word.trim();
    if (trimmedWord.isEmpty) {
      throw ArgumentError('word must not be empty');
    }

    final currentTime = now ?? DateTime.now();
    final effectiveContextText = _normalizeOptionalText(contextText);
    final sourceSentence = extractSourceSentence(
      trimmedWord,
      effectiveContextText,
    );
    final contextWindow = extractContextWindow(
      trimmedWord,
      effectiveContextText,
      sourceSentence,
    );
    final translator = translateLookup ?? translateTextOnly;
    final lookupDictionary =
        dictionaryLookup ?? EnglishDictionaryService.lookup;
    final existing = await vocabularyDao.selectByWord(trimmedWord);
    final item = await _buildEnrichedItem(
      existing: existing,
      word: trimmedWord,
      bookId: bookId,
      bookTitle: bookTitle,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      sourceSentence: sourceSentence,
      contextBefore: contextWindow.before,
      contextAfter: contextWindow.after,
      position: position,
      translator: translator,
      lookupDictionary: lookupDictionary,
      translateToCode: translateToCode ?? Prefs().translateTo.code,
      contextText: effectiveContextText,
      now: currentTime,
    );

    return _persistComposedItem(existing: existing, item: item);
  }

  static String extractSourceSentence(String word, String? contextText) {
    final text = _normalizeOptionalText(contextText);
    if (text == null) {
      return word;
    }

    final lowerText = text.toLowerCase();
    final index = lowerText.indexOf(word.toLowerCase());
    if (index == -1) {
      return text;
    }

    final sentenceStart = text.lastIndexOf(RegExp(r'[.!?。！？\n]'), index);
    final sentenceEnd = text.indexOf(RegExp(r'[.!?。！？\n]'), index);
    final start = sentenceStart == -1 ? 0 : sentenceStart + 1;
    final end = sentenceEnd == -1 ? text.length : sentenceEnd + 1;
    return text.substring(start, end).trim();
  }

  static VocabularyContextWindow extractContextWindow(
    String word,
    String? contextText,
    String sourceSentence,
  ) {
    final text = _normalizeOptionalText(contextText);
    if (text == null || text == sourceSentence) {
      return const VocabularyContextWindow(before: null, after: null);
    }

    final lowerText = text.toLowerCase();
    final lowerSentence = sourceSentence.toLowerCase();
    final sentenceIndex = lowerText.indexOf(lowerSentence);
    if (sentenceIndex != -1) {
      final before = text.substring(0, sentenceIndex).trim();
      final after =
          text.substring(sentenceIndex + sourceSentence.length).trim();
      return VocabularyContextWindow(
        before: before.isEmpty ? null : before,
        after: after.isEmpty ? null : after,
      );
    }

    final wordIndex = lowerText.indexOf(word.toLowerCase());
    if (wordIndex == -1) {
      return const VocabularyContextWindow(before: null, after: null);
    }

    final before = text.substring(0, wordIndex).trim();
    final after = text.substring(wordIndex + word.length).trim();
    return VocabularyContextWindow(
      before: before.isEmpty ? null : before,
      after: after.isEmpty ? null : after,
    );
  }

  static VocabularyItem _composeItem({
    required VocabularyItem? existing,
    required String word,
    required String bookId,
    required String? bookTitle,
    required String? chapterId,
    required String? chapterTitle,
    required String sourceSentence,
    required String? sourceSentenceTranslation,
    required String? contextualDefinition,
    required String? contextBefore,
    required String? contextAfter,
    required String? position,
    required EnglishDictionaryEntry? dictionaryEntry,
    required String translateToCode,
    required DateTime now,
  }) {
    final translatedDefinition = _normalizeOptionalText(contextualDefinition);
    final englishDefinition = _pickEnglishDefinition(
      dictionaryEntry: dictionaryEntry,
      translatedDefinition: translatedDefinition,
      translateToCode: translateToCode,
      existingValue: existing?.definitionEn,
    );
    final chineseDefinition = _pickChineseDefinition(
      translatedDefinition: translatedDefinition,
      translateToCode: translateToCode,
      existingValue: existing?.definitionCn,
    );
    final sourceTranslation = _normalizeOptionalText(sourceSentenceTranslation);
    final useDictionaryExample =
        sourceSentence == word && _isPresent(dictionaryEntry?.exampleSentence);
    final exampleSentence = useDictionaryExample
        ? dictionaryEntry!.exampleSentence
        : sourceSentence;
    final exampleTranslation = useDictionaryExample
        ? existing?.exampleTranslation
        : _preferNonEmpty(sourceTranslation, existing?.exampleTranslation);

    return VocabularyItem(
      id: existing?.id ?? const Uuid().v4(),
      word: existing?.word ?? word,
      lemma: _preferNonEmpty(
        dictionaryEntry?.lemma,
        _nullableNormalizedWord(word),
        existing?.lemma,
      ),
      phonetic: _preferNonEmpty(
        dictionaryEntry?.phonetic,
        existing?.phonetic,
      ),
      definitionCn: chineseDefinition,
      definitionEn: englishDefinition,
      partOfSpeech: _preferNonEmpty(
        dictionaryEntry?.partOfSpeech,
        existing?.partOfSpeech,
      ),
      audioUrl: _preferNonEmpty(
        dictionaryEntry?.audioUrl,
        existing?.audioUrl,
      ),
      bookId: existing?.bookId.isNotEmpty == true ? existing!.bookId : bookId,
      bookTitle: _preferNonEmpty(bookTitle, existing?.bookTitle),
      chapterId: _preferNonEmpty(chapterId, existing?.chapterId),
      chapterTitle: _preferNonEmpty(chapterTitle, existing?.chapterTitle),
      sourceSentence:
          _preferNonEmpty(sourceSentence, existing?.sourceSentence) ?? word,
      sourceSentenceTranslation: _preferNonEmpty(
        sourceTranslation,
        existing?.sourceSentenceTranslation,
      ),
      contextualDefinition: _preferNonEmpty(
        translatedDefinition,
        englishDefinition,
        chineseDefinition,
        existing?.contextualDefinition,
      ),
      contextBefore: _preferNonEmpty(contextBefore, existing?.contextBefore),
      contextAfter: _preferNonEmpty(contextAfter, existing?.contextAfter),
      exampleSentence: _preferNonEmpty(
        exampleSentence,
        existing?.exampleSentence,
      ),
      exampleTranslation: exampleTranslation,
      position: _preferNonEmpty(position, existing?.position),
      reviewStage: existing?.reviewStage ?? 0,
      nextReviewAt: existing?.nextReviewAt ?? now,
      lastReviewedAt: existing?.lastReviewedAt,
      familiarity: existing?.familiarity ?? VocabularyFamiliarity.newWord,
      correctCount: existing?.correctCount ?? 0,
      wrongCount: existing?.wrongCount ?? 0,
      isMastered: existing?.isMastered ?? false,
      createdAt: existing?.createdAt ?? now,
      updatedAt: now,
    );
  }

  static String? _pickEnglishDefinition({
    required EnglishDictionaryEntry? dictionaryEntry,
    required String? translatedDefinition,
    required String translateToCode,
    required String? existingValue,
  }) {
    if (_isPresent(dictionaryEntry?.definitionEn)) {
      return dictionaryEntry!.definitionEn;
    }
    if (!translateToCode.startsWith('zh') && _isPresent(translatedDefinition)) {
      return translatedDefinition;
    }
    return existingValue;
  }

  static String? _pickChineseDefinition({
    required String? translatedDefinition,
    required String translateToCode,
    required String? existingValue,
  }) {
    if (translateToCode.startsWith('zh') && _isPresent(translatedDefinition)) {
      return translatedDefinition;
    }
    return existingValue;
  }

  static Future<String?> _safeTranslate(
    VocabularyTranslationLookup translator,
    String text, {
    String? contextText,
  }) async {
    try {
      return _normalizeOptionalText(
        await translator(text, contextText: contextText),
      );
    } catch (_) {
      return null;
    }
  }

  static Future<_VocabularyCaptureDraft?> _buildDraft({
    required String word,
    required String? contextText,
    required VocabularyTranslationLookup translator,
    required Future<EnglishDictionaryEntry?> Function(String word)
        lookupDictionary,
  }) async {
    final sourceSentence = extractSourceSentence(word, contextText);
    final contextWindow =
        extractContextWindow(word, contextText, sourceSentence);

    final dictionaryEntryFuture = lookupDictionary(word);
    final wordDefinitionFuture = _safeTranslate(
      translator,
      word,
      contextText: contextText,
    );
    final sourceSentenceTranslationFuture =
        sourceSentence.isNotEmpty && sourceSentence != word
            ? _safeTranslate(
                translator,
                sourceSentence,
                contextText: contextText,
              )
            : Future<String?>.value(null);

    final dictionaryEntry = await dictionaryEntryFuture;
    final wordDefinition = await wordDefinitionFuture;
    final sourceSentenceTranslation = await sourceSentenceTranslationFuture;

    if (dictionaryEntry == null &&
        !_isPresent(wordDefinition) &&
        !_isPresent(sourceSentenceTranslation)) {
      return null;
    }

    return _VocabularyCaptureDraft(
      sourceSentence: sourceSentence,
      sourceSentenceTranslation: sourceSentenceTranslation,
      contextualDefinition: wordDefinition,
      contextBefore: contextWindow.before,
      contextAfter: contextWindow.after,
      dictionaryEntry: dictionaryEntry,
    );
  }

  static Future<VocabularyItem> _buildEnrichedItem({
    required VocabularyItem? existing,
    required String word,
    required String bookId,
    required String? bookTitle,
    required String? chapterId,
    required String? chapterTitle,
    required String sourceSentence,
    required String? contextBefore,
    required String? contextAfter,
    required String? position,
    required VocabularyTranslationLookup translator,
    required Future<EnglishDictionaryEntry?> Function(String word)
        lookupDictionary,
    required String translateToCode,
    required String? contextText,
    required DateTime now,
    _VocabularyCaptureDraft? draft,
  }) async {
    if (draft != null) {
      return _composeItem(
        existing: existing,
        word: word,
        bookId: bookId,
        bookTitle: bookTitle,
        chapterId: chapterId,
        chapterTitle: chapterTitle,
        sourceSentence: draft.sourceSentence,
        sourceSentenceTranslation: draft.sourceSentenceTranslation,
        contextualDefinition: draft.contextualDefinition,
        contextBefore: draft.contextBefore,
        contextAfter: draft.contextAfter,
        position: position,
        dictionaryEntry: draft.dictionaryEntry,
        translateToCode: translateToCode,
        now: now,
      );
    }

    final dictionaryEntryFuture = lookupDictionary(word);
    final wordDefinitionFuture = _safeTranslate(
      translator,
      word,
      contextText: contextText,
    );
    final sourceSentenceTranslationFuture =
        sourceSentence.isNotEmpty && sourceSentence != word
            ? _safeTranslate(
                translator,
                sourceSentence,
                contextText: contextText,
              )
            : Future<String?>.value(null);

    final dictionaryEntry = await dictionaryEntryFuture;
    final wordDefinition = await wordDefinitionFuture;
    final sourceSentenceTranslation = await sourceSentenceTranslationFuture;

    return _composeItem(
      existing: existing,
      word: word,
      bookId: bookId,
      bookTitle: bookTitle,
      chapterId: chapterId,
      chapterTitle: chapterTitle,
      sourceSentence: sourceSentence,
      sourceSentenceTranslation: sourceSentenceTranslation,
      contextualDefinition: wordDefinition,
      contextBefore: contextBefore,
      contextAfter: contextAfter,
      position: position,
      dictionaryEntry: dictionaryEntry,
      translateToCode: translateToCode,
      now: now,
    );
  }

  static Future<void> _enrichStoredItem({
    required VocabularyItem existing,
    required VocabularyTranslationLookup translateLookup,
    required Future<EnglishDictionaryEntry?> Function(String word)
        dictionaryLookup,
    required String translateToCode,
  }) async {
    try {
      final mergedContext = _mergeContextText(existing);
      final draftKey = _draftCacheKey(
        word: existing.word,
        contextText: mergedContext,
        translateToCode: translateToCode,
      );
      final draft = _draftCache[draftKey] ??
          await _draftTasks[draftKey] ??
          await _buildDraft(
            word: existing.word,
            contextText: mergedContext,
            translator: translateLookup,
            lookupDictionary: dictionaryLookup,
          );
      if (draft != null) {
        _rememberDraft(draftKey, draft);
      }

      final enriched = await _buildEnrichedItem(
        existing: existing,
        word: existing.word,
        bookId: existing.bookId,
        bookTitle: existing.bookTitle,
        chapterId: existing.chapterId,
        chapterTitle: existing.chapterTitle,
        sourceSentence: existing.sourceSentence,
        contextBefore: existing.contextBefore,
        contextAfter: existing.contextAfter,
        position: existing.position,
        translator: translateLookup,
        lookupDictionary: dictionaryLookup,
        translateToCode: translateToCode,
        contextText: mergedContext,
        now: DateTime.now(),
        draft: draft,
      );

      if (_hasDiff(existing, enriched)) {
        await vocabularyDao.updateItem(enriched);
      }
    } catch (_) {
      // Keep add-to-vocabulary responsive even if background enrichment fails.
    }
  }

  static Future<VocabularyCaptureResult> _persistComposedItem({
    required VocabularyItem? existing,
    required VocabularyItem item,
  }) async {
    if (existing == null) {
      await vocabularyDao.save(item);
      return VocabularyCaptureResult(
        item: item,
        created: true,
        updated: false,
      );
    }

    if (_hasDiff(existing, item)) {
      await vocabularyDao.updateItem(item);
      return VocabularyCaptureResult(
        item: item,
        created: false,
        updated: true,
      );
    }

    return VocabularyCaptureResult(
      item: existing,
      created: false,
      updated: false,
    );
  }

  static String? _mergeContextText(VocabularyItem item) {
    final segments = [
      item.contextBefore,
      item.sourceSentence,
      item.contextAfter,
    ].where((segment) => _isPresent(segment)).map((segment) => segment!.trim());

    final merged = segments.join(' ').trim();
    return merged.isEmpty ? null : merged;
  }

  static String _draftCacheKey({
    required String word,
    required String? contextText,
    required String translateToCode,
  }) {
    final normalizedWord = VocabularyItem.normalizeWord(word);
    final normalizedContext =
        contextText?.trim().replaceAll(RegExp(r'\s+'), ' ') ?? '';
    return '$translateToCode|$normalizedWord|$normalizedContext';
  }

  static void _rememberDraft(String key, _VocabularyCaptureDraft draft) {
    if (_draftCache.length >= _maxDraftCacheSize) {
      _draftCache.remove(_draftCache.keys.first);
    }
    _draftCache[key] = draft;
  }

  static bool _hasDiff(VocabularyItem left, VocabularyItem right) {
    return left.copyWith(updatedAt: right.updatedAt).toJson().toString() !=
        right.toJson().toString();
  }

  static String? _nullableNormalizedWord(String word) {
    final normalized = VocabularyItem.normalizeWord(word);
    if (normalized.isEmpty) return null;
    return normalized;
  }

  static String? _normalizeOptionalText(String? value) {
    final trimmed = value?.trim();
    return trimmed == null || trimmed.isEmpty ? null : trimmed;
  }

  static bool _isPresent(String? value) {
    return value?.trim().isNotEmpty ?? false;
  }

  static String? _preferNonEmpty(
    String? first, [
    String? second,
    String? third,
    String? fourth,
  ]) {
    for (final value in [first, second, third, fourth]) {
      final normalized = _normalizeOptionalText(value);
      if (normalized != null) {
        return normalized;
      }
    }
    return null;
  }
}

class VocabularyContextWindow {
  const VocabularyContextWindow({
    required this.before,
    required this.after,
  });

  final String? before;
  final String? after;
}

class _VocabularyCaptureDraft {
  const _VocabularyCaptureDraft({
    required this.sourceSentence,
    required this.sourceSentenceTranslation,
    required this.contextualDefinition,
    required this.contextBefore,
    required this.contextAfter,
    required this.dictionaryEntry,
  });

  final String sourceSentence;
  final String? sourceSentenceTranslation;
  final String? contextualDefinition;
  final String? contextBefore;
  final String? contextAfter;
  final EnglishDictionaryEntry? dictionaryEntry;
}
