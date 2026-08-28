import 'dart:convert';

enum InspectionGuideStatus { notStarted, inProgress, completed, dismissed }

enum ReadingMasteryLevel { needsReview, developing, solid }

enum ReadingDifficultyStatus { unresolved, resolved }

enum ReadingDifficultyType {
  concept,
  argument,
  background,
  question,
  later,
}

class ActiveReadingAnswer {
  const ActiveReadingAnswer({
    required this.questionId,
    this.selected = const [],
    this.note,
    required this.updatedAt,
  });

  final String questionId;
  final List<String> selected;
  final String? note;
  final int updatedAt;

  Map<String, dynamic> toJson() => {
        'questionId': questionId,
        'selected': selected,
        if (note?.trim().isNotEmpty == true) 'note': note!.trim(),
        'updatedAt': updatedAt,
      };

  factory ActiveReadingAnswer.fromJson(Map<String, dynamic> json) {
    return ActiveReadingAnswer(
      questionId: json['questionId']?.toString() ?? '',
      selected: (json['selected'] as List? ?? const [])
          .map((value) => value.toString())
          .toList(growable: false),
      note: json['note']?.toString(),
      updatedAt: _readInt(json['updatedAt']),
    );
  }
}

class InspectionReadingGuide {
  const InspectionReadingGuide({
    required this.bookId,
    this.status = InspectionGuideStatus.notStarted,
    this.topicChoice,
    this.goalChoice,
    this.note,
    this.report,
    this.answers = const {},
    required this.updatedAt,
  });

  final int bookId;
  final InspectionGuideStatus status;
  final String? topicChoice;
  final String? goalChoice;
  final String? note;
  final Map<String, dynamic>? report;
  final Map<String, ActiveReadingAnswer> answers;
  final int updatedAt;

  InspectionReadingGuide copyWith({
    InspectionGuideStatus? status,
    String? topicChoice,
    String? goalChoice,
    String? note,
    Map<String, dynamic>? report,
    Map<String, ActiveReadingAnswer>? answers,
    int? updatedAt,
  }) {
    return InspectionReadingGuide(
      bookId: bookId,
      status: status ?? this.status,
      topicChoice: topicChoice ?? this.topicChoice,
      goalChoice: goalChoice ?? this.goalChoice,
      note: note ?? this.note,
      report: report ?? this.report,
      answers: answers ?? this.answers,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, Object?> toDb() => {
        'book_id': bookId,
        'status': status.name,
        'topic_choice': topicChoice,
        'goal_choice': goalChoice,
        'note': note,
        'report': report == null ? null : jsonEncode(report),
        'answers': jsonEncode(
          answers.map((key, value) => MapEntry(key, value.toJson())),
        ),
        'updated_at': updatedAt,
      };

  factory InspectionReadingGuide.fromDb(Map<String, dynamic> row) {
    final rawAnswers = _decodeMap(row['answers']);
    return InspectionReadingGuide(
      bookId: _readInt(row['book_id']),
      status: InspectionGuideStatus.values.firstWhere(
        (value) => value.name == row['status'],
        orElse: () => InspectionGuideStatus.notStarted,
      ),
      topicChoice: row['topic_choice']?.toString(),
      goalChoice: row['goal_choice']?.toString(),
      note: row['note']?.toString(),
      report: _decodeMap(row['report']),
      answers: rawAnswers.map(
        (key, value) => MapEntry(
          key,
          ActiveReadingAnswer.fromJson(
            Map<String, dynamic>.from(value as Map),
          ),
        ),
      ),
      updatedAt: _readInt(row['updated_at']),
    );
  }
}

class ChapterQuiz {
  const ChapterQuiz({
    required this.id,
    required this.bookId,
    required this.chapterHref,
    this.chapterTitle,
    this.questions = const [],
    this.answers = const {},
    this.mastery,
    this.completed = false,
    required this.updatedAt,
  });

  final String id;
  final int bookId;
  final String chapterHref;
  final String? chapterTitle;
  final List<Map<String, dynamic>> questions;
  final Map<String, List<String>> answers;
  final ReadingMasteryLevel? mastery;
  final bool completed;
  final int updatedAt;

  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'chapter_href': chapterHref,
        'chapter_title': chapterTitle,
        'questions': jsonEncode(questions),
        'answers': jsonEncode(answers),
        'mastery': mastery?.name,
        'completed': completed ? 1 : 0,
        'updated_at': updatedAt,
      };

  factory ChapterQuiz.fromDb(Map<String, dynamic> row) => ChapterQuiz(
        id: row['id']?.toString() ?? '',
        bookId: _readInt(row['book_id']),
        chapterHref: row['chapter_href']?.toString() ?? '',
        chapterTitle: row['chapter_title']?.toString(),
        questions: _decodeList(row['questions'])
            .whereType<Map>()
            .map((value) => Map<String, dynamic>.from(value))
            .toList(growable: false),
        answers: _decodeMap(row['answers']).map(
          (key, value) => MapEntry(
            key,
            (value as List).map((item) => item.toString()).toList(),
          ),
        ),
        mastery: ReadingMasteryLevel.values
            .where((value) => value.name == row['mastery'])
            .firstOrNull,
        completed: row['completed'] == 1,
        updatedAt: _readInt(row['updated_at']),
      );
}

class ReadingDifficulty {
  const ReadingDifficulty({
    required this.id,
    required this.bookId,
    required this.cfi,
    required this.text,
    this.chapterHref,
    this.chapterTitle,
    this.context,
    this.type = ReadingDifficultyType.later,
    this.status = ReadingDifficultyStatus.unresolved,
    this.note,
    required this.createdAt,
    required this.updatedAt,
  });

  final String id;
  final int bookId;
  final String cfi;
  final String text;
  final String? chapterHref;
  final String? chapterTitle;
  final String? context;
  final ReadingDifficultyType type;
  final ReadingDifficultyStatus status;
  final String? note;
  final int createdAt;
  final int updatedAt;

  ReadingDifficulty copyWith({
    ReadingDifficultyType? type,
    ReadingDifficultyStatus? status,
    String? note,
    int? updatedAt,
  }) =>
      ReadingDifficulty(
        id: id,
        bookId: bookId,
        cfi: cfi,
        text: text,
        chapterHref: chapterHref,
        chapterTitle: chapterTitle,
        context: context,
        type: type ?? this.type,
        status: status ?? this.status,
        note: note ?? this.note,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'cfi': cfi,
        'selected_text': text,
        'chapter_href': chapterHref,
        'chapter_title': chapterTitle,
        'context': context,
        'difficulty_type': type.name,
        'status': status.name,
        'note': note,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory ReadingDifficulty.fromDb(Map<String, dynamic> row) =>
      ReadingDifficulty(
        id: row['id']?.toString() ?? '',
        bookId: _readInt(row['book_id']),
        cfi: row['cfi']?.toString() ?? '',
        text: row['selected_text']?.toString() ?? '',
        chapterHref: row['chapter_href']?.toString(),
        chapterTitle: row['chapter_title']?.toString(),
        context: row['context']?.toString(),
        type: ReadingDifficultyType.values.firstWhere(
          (value) => value.name == row['difficulty_type'],
          orElse: () => ReadingDifficultyType.later,
        ),
        status: ReadingDifficultyStatus.values.firstWhere(
          (value) => value.name == row['status'],
          orElse: () => ReadingDifficultyStatus.unresolved,
        ),
        note: row['note']?.toString(),
        createdAt: _readInt(row['created_at']),
        updatedAt: _readInt(row['updated_at']),
      );
}

int _readInt(Object? value) =>
    value is int ? value : int.tryParse(value?.toString() ?? '') ?? 0;

Map<String, dynamic> _decodeMap(Object? value) {
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is! String || value.isEmpty) return {};
  final decoded = jsonDecode(value);
  return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
}

List<dynamic> _decodeList(Object? value) {
  if (value is List) return value;
  if (value is! String || value.isEmpty) return const [];
  final decoded = jsonDecode(value);
  return decoded is List ? decoded : const [];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
