enum VocabularyFamiliarity {
  newWord,
  hard,
  familiar,
  mastered,
}

extension VocabularyFamiliarityCodec on VocabularyFamiliarity {
  String get code {
    switch (this) {
      case VocabularyFamiliarity.newWord:
        return 'newWord';
      case VocabularyFamiliarity.hard:
        return 'hard';
      case VocabularyFamiliarity.familiar:
        return 'familiar';
      case VocabularyFamiliarity.mastered:
        return 'mastered';
    }
  }

  static VocabularyFamiliarity fromCode(String? code) {
    switch (code) {
      case 'hard':
        return VocabularyFamiliarity.hard;
      case 'familiar':
        return VocabularyFamiliarity.familiar;
      case 'mastered':
        return VocabularyFamiliarity.mastered;
      case 'newWord':
      default:
        return VocabularyFamiliarity.newWord;
    }
  }
}

class VocabularyItem {
  final String id;

  // Word details
  final String word;
  final String? lemma;
  final String? phonetic;
  final String? definitionCn;
  final String? definitionEn;
  final String? partOfSpeech;
  final String? audioUrl;

  // Reading source
  final String bookId;
  final String? bookTitle;
  final String? chapterId;
  final String? chapterTitle;
  final String sourceSentence;
  final String? sourceSentenceTranslation;
  final String? contextualDefinition;
  final String? contextBefore;
  final String? contextAfter;
  final String? exampleSentence;
  final String? exampleTranslation;
  final String? position;

  // Review state
  final int reviewStage;
  final DateTime nextReviewAt;
  final DateTime? lastReviewedAt;
  final VocabularyFamiliarity familiarity;
  final int correctCount;
  final int wrongCount;
  final bool isMastered;

  // Timestamps
  final DateTime createdAt;
  final DateTime updatedAt;

  const VocabularyItem({
    required this.id,
    required this.word,
    this.lemma,
    this.phonetic,
    this.definitionCn,
    this.definitionEn,
    this.partOfSpeech,
    this.audioUrl,
    required this.bookId,
    this.bookTitle,
    this.chapterId,
    this.chapterTitle,
    required this.sourceSentence,
    this.sourceSentenceTranslation,
    this.contextualDefinition,
    this.contextBefore,
    this.contextAfter,
    this.exampleSentence,
    this.exampleTranslation,
    this.position,
    required this.reviewStage,
    required this.nextReviewAt,
    this.lastReviewedAt,
    required this.familiarity,
    required this.correctCount,
    required this.wrongCount,
    required this.isMastered,
    required this.createdAt,
    required this.updatedAt,
  });

  VocabularyItem copyWith({
    String? id,
    String? word,
    String? lemma,
    String? phonetic,
    String? definitionCn,
    String? definitionEn,
    String? partOfSpeech,
    String? audioUrl,
    String? bookId,
    String? bookTitle,
    String? chapterId,
    String? chapterTitle,
    String? sourceSentence,
    String? sourceSentenceTranslation,
    String? contextualDefinition,
    String? contextBefore,
    String? contextAfter,
    String? exampleSentence,
    String? exampleTranslation,
    String? position,
    int? reviewStage,
    DateTime? nextReviewAt,
    DateTime? lastReviewedAt,
    VocabularyFamiliarity? familiarity,
    int? correctCount,
    int? wrongCount,
    bool? isMastered,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return VocabularyItem(
      id: id ?? this.id,
      word: word ?? this.word,
      lemma: lemma ?? this.lemma,
      phonetic: phonetic ?? this.phonetic,
      definitionCn: definitionCn ?? this.definitionCn,
      definitionEn: definitionEn ?? this.definitionEn,
      partOfSpeech: partOfSpeech ?? this.partOfSpeech,
      audioUrl: audioUrl ?? this.audioUrl,
      bookId: bookId ?? this.bookId,
      bookTitle: bookTitle ?? this.bookTitle,
      chapterId: chapterId ?? this.chapterId,
      chapterTitle: chapterTitle ?? this.chapterTitle,
      sourceSentence: sourceSentence ?? this.sourceSentence,
      sourceSentenceTranslation:
          sourceSentenceTranslation ?? this.sourceSentenceTranslation,
      contextualDefinition: contextualDefinition ?? this.contextualDefinition,
      contextBefore: contextBefore ?? this.contextBefore,
      contextAfter: contextAfter ?? this.contextAfter,
      exampleSentence: exampleSentence ?? this.exampleSentence,
      exampleTranslation: exampleTranslation ?? this.exampleTranslation,
      position: position ?? this.position,
      reviewStage: reviewStage ?? this.reviewStage,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
      familiarity: familiarity ?? this.familiarity,
      correctCount: correctCount ?? this.correctCount,
      wrongCount: wrongCount ?? this.wrongCount,
      isMastered: isMastered ?? this.isMastered,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'word': word,
      'lemma': lemma,
      'phonetic': phonetic,
      'definitionCn': definitionCn,
      'definitionEn': definitionEn,
      'partOfSpeech': partOfSpeech,
      'audioUrl': audioUrl,
      'bookId': bookId,
      'bookTitle': bookTitle,
      'chapterId': chapterId,
      'chapterTitle': chapterTitle,
      'sourceSentence': sourceSentence,
      'sourceSentenceTranslation': sourceSentenceTranslation,
      'contextualDefinition': contextualDefinition,
      'contextBefore': contextBefore,
      'contextAfter': contextAfter,
      'exampleSentence': exampleSentence,
      'exampleTranslation': exampleTranslation,
      'position': position,
      'reviewStage': reviewStage,
      'nextReviewAt': nextReviewAt.toIso8601String(),
      'lastReviewedAt': lastReviewedAt?.toIso8601String(),
      'familiarity': familiarity.code,
      'correctCount': correctCount,
      'wrongCount': wrongCount,
      'isMastered': isMastered,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  factory VocabularyItem.fromJson(Map<String, dynamic> json) {
    return VocabularyItem(
      id: json['id'] as String,
      word: json['word'] as String,
      lemma: json['lemma'] as String?,
      phonetic: json['phonetic'] as String?,
      definitionCn: json['definitionCn'] as String?,
      definitionEn: json['definitionEn'] as String?,
      partOfSpeech: json['partOfSpeech'] as String?,
      audioUrl: json['audioUrl'] as String?,
      bookId: json['bookId'] as String,
      bookTitle: json['bookTitle'] as String?,
      chapterId: json['chapterId'] as String?,
      chapterTitle: json['chapterTitle'] as String?,
      sourceSentence: json['sourceSentence'] as String,
      sourceSentenceTranslation: json['sourceSentenceTranslation'] as String?,
      contextualDefinition: json['contextualDefinition'] as String?,
      contextBefore: json['contextBefore'] as String?,
      contextAfter: json['contextAfter'] as String?,
      exampleSentence: json['exampleSentence'] as String?,
      exampleTranslation: json['exampleTranslation'] as String?,
      position: json['position'] as String?,
      reviewStage: (json['reviewStage'] as num?)?.toInt() ?? 0,
      nextReviewAt: DateTime.parse(json['nextReviewAt'] as String),
      lastReviewedAt: _parseOptionalDate(json['lastReviewedAt']),
      familiarity:
          VocabularyFamiliarityCodec.fromCode(json['familiarity'] as String?),
      correctCount: (json['correctCount'] as num?)?.toInt() ?? 0,
      wrongCount: (json['wrongCount'] as num?)?.toInt() ?? 0,
      isMastered: _parseBool(json['isMastered']),
      createdAt: DateTime.parse(json['createdAt'] as String),
      updatedAt: DateTime.parse(json['updatedAt'] as String),
    );
  }

  Map<String, Object?> toDb() {
    return {
      'id': id,
      'word': word,
      'normalized_word': normalizeWord(word),
      'lemma': lemma,
      'phonetic': phonetic,
      'definition_cn': definitionCn,
      'definition_en': definitionEn,
      'part_of_speech': partOfSpeech,
      'audio_url': audioUrl,
      'book_id': bookId,
      'book_title': bookTitle,
      'chapter_id': chapterId,
      'chapter_title': chapterTitle,
      'source_sentence': sourceSentence,
      'source_sentence_translation': sourceSentenceTranslation,
      'contextual_definition': contextualDefinition,
      'context_before': contextBefore,
      'context_after': contextAfter,
      'example_sentence': exampleSentence,
      'example_translation': exampleTranslation,
      'position': position,
      'review_stage': reviewStage,
      'next_review_at': nextReviewAt.toIso8601String(),
      'last_reviewed_at': lastReviewedAt?.toIso8601String(),
      'familiarity': familiarity.code,
      'correct_count': correctCount,
      'wrong_count': wrongCount,
      'is_mastered': isMastered ? 1 : 0,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory VocabularyItem.fromDb(Map<String, dynamic> row) {
    return VocabularyItem(
      id: row['id'] as String,
      word: row['word'] as String? ?? '',
      lemma: row['lemma'] as String?,
      phonetic: row['phonetic'] as String?,
      definitionCn: row['definition_cn'] as String?,
      definitionEn: row['definition_en'] as String?,
      partOfSpeech: row['part_of_speech'] as String?,
      audioUrl: row['audio_url'] as String?,
      bookId: row['book_id'] as String? ?? '',
      bookTitle: row['book_title'] as String?,
      chapterId: row['chapter_id'] as String?,
      chapterTitle: row['chapter_title'] as String?,
      sourceSentence: row['source_sentence'] as String? ?? '',
      sourceSentenceTranslation: row['source_sentence_translation'] as String?,
      contextualDefinition: row['contextual_definition'] as String?,
      contextBefore: row['context_before'] as String?,
      contextAfter: row['context_after'] as String?,
      exampleSentence: row['example_sentence'] as String?,
      exampleTranslation: row['example_translation'] as String?,
      position: row['position'] as String?,
      reviewStage: row['review_stage'] as int? ?? 0,
      nextReviewAt: _parseOptionalDate(row['next_review_at']) ?? DateTime.now(),
      lastReviewedAt: _parseOptionalDate(row['last_reviewed_at']),
      familiarity:
          VocabularyFamiliarityCodec.fromCode(row['familiarity'] as String?),
      correctCount: row['correct_count'] as int? ?? 0,
      wrongCount: row['wrong_count'] as int? ?? 0,
      isMastered: (row['is_mastered'] as int? ?? 0) == 1,
      createdAt: _parseOptionalDate(row['created_at']) ?? DateTime.now(),
      updatedAt: _parseOptionalDate(row['updated_at']) ?? DateTime.now(),
    );
  }

  static String normalizeWord(String word) {
    final trimmed = word.trim().toLowerCase();
    final normalized = trimmed
        .replaceAll(
            RegExp(r'^[^a-z0-9]+|[^a-z0-9]+$', caseSensitive: false), '')
        .replaceAll(RegExp(r'\s+'), ' ');
    return normalized.isEmpty ? trimmed : normalized;
  }

  static DateTime? _parseOptionalDate(Object? value) {
    if (value == null) return null;
    return DateTime.tryParse(value.toString());
  }

  static bool _parseBool(Object? value) {
    if (value is bool) return value;
    if (value is num) return value != 0;
    if (value is String) return value == 'true' || value == '1';
    return false;
  }
}
