import 'dart:convert';

import 'package:anx_reader/models/reading_coach.dart';

const activeReadingQuestionIds = ['whole', 'detail', 'truth', 'relation'];

Map<String, dynamic> parsePersonalizedGuideResponse(String response) {
  final decoded = _decodeObject(response);
  final topics = _stringList(decoded['topics'], min: 3, max: 4);
  final structure = _stringList(decoded['structure'], min: 2, max: 6);
  final plan = _stringList(decoded['plan'], min: 2, max: 4);
  final keyChapters =
      _objectList(decoded['keyChapters'], min: 1, max: 6).map((item) {
    final title = _requiredString(item['title']);
    final href = _requiredString(item['href']);
    final reason = _requiredString(item['reason']);
    return {'title': title, 'href': href, 'reason': reason};
  }).toList(growable: false);
  final rawQuestions = decoded['questionOptions'];
  if (rawQuestions is! Map) {
    throw const FormatException('questionOptions must be an object');
  }
  final questionOptions = <String, List<String>>{};
  for (final id in activeReadingQuestionIds) {
    final options = _stringList(rawQuestions[id], min: 3, max: 5);
    _ensureUncertainExit(options, '暂不确定', max: 5);
    questionOptions[id] = options;
  }
  _ensureUncertainExit(topics, '我还不确定', max: 4);
  return {
    'version': 2,
    'bookType': _requiredString(decoded['bookType']),
    'coreQuestion': _requiredString(decoded['coreQuestion']),
    'topics': topics,
    'structure': structure,
    'keyChapters': keyChapters,
    'plan': plan,
    'questionOptions': questionOptions,
  };
}

Map<String, dynamic> parseReadingSynthesisResponse(String response) {
  final decoded = _decodeObject(response);
  return {
    'summary': _requiredString(decoded['summary']),
    'keyIdeas': _stringList(decoded['keyIdeas'], min: 3, max: 6),
    'actions': _stringList(decoded['actions'], min: 1, max: 4),
    'openQuestions': _stringList(decoded['openQuestions'], min: 1, max: 4),
  };
}

List<int> representativeChapterIndexes(int chapterCount, {int limit = 6}) {
  if (chapterCount <= 0 || limit <= 0) return const [];
  if (chapterCount <= limit) {
    return List.generate(chapterCount, (index) => index);
  }
  final indexes = <int>{0, 1, chapterCount - 1};
  final remaining = limit - indexes.length;
  for (var step = 1; step <= remaining; step++) {
    indexes.add(((chapterCount - 1) * step / (remaining + 1)).round());
  }
  return indexes.toList()..sort();
}

String boundedChapterSample(
  String content, {
  int headCharacters = 2000,
  int tailCharacters = 1000,
}) {
  final text = content.trim();
  if (text.length <= headCharacters + tailCharacters) return text;
  return '${text.substring(0, headCharacters)}\n…\n'
      '${text.substring(text.length - tailCharacters)}';
}

List<ChapterQuiz> dueReviewQuizzes(
  Iterable<ChapterQuiz> quizzes, {
  required int now,
}) {
  const day = Duration.millisecondsPerDay;
  final due = quizzes.where((quiz) {
    if (!quiz.completed || quiz.mastery == null) return false;
    final age = now - quiz.updatedAt;
    return switch (quiz.mastery!) {
      ReadingMasteryLevel.needsReview => age >= day,
      ReadingMasteryLevel.developing => age >= 3 * day,
      ReadingMasteryLevel.solid => age >= 7 * day,
    };
  }).toList();
  due.sort((left, right) {
    final mastery = left.mastery!.index.compareTo(right.mastery!.index);
    return mastery != 0 ? mastery : left.updatedAt.compareTo(right.updatedAt);
  });
  return due;
}

Map<String, dynamic> _decodeObject(String response) {
  final cleaned = response
      .replaceFirst(RegExp(r'^\s*```(?:json)?', caseSensitive: false), '')
      .replaceFirst(RegExp(r'```\s*$'), '')
      .trim();
  final decoded = jsonDecode(cleaned);
  if (decoded is! Map) throw const FormatException('Expected JSON object');
  return Map<String, dynamic>.from(decoded);
}

String _requiredString(Object? value) {
  final text = value?.toString().trim() ?? '';
  if (text.isEmpty) throw const FormatException('Expected non-empty string');
  return text;
}

List<String> _stringList(Object? value, {required int min, required int max}) {
  if (value is! List || value.length < min || value.length > max) {
    throw FormatException('Expected $min-$max items');
  }
  final result = value.map(_requiredString).toList(growable: true);
  if (result.toSet().length != result.length) {
    throw const FormatException('Items must be unique');
  }
  return result;
}

List<Map<String, dynamic>> _objectList(
  Object? value, {
  required int min,
  required int max,
}) {
  if (value is! List || value.length < min || value.length > max) {
    throw FormatException('Expected $min-$max objects');
  }
  return value.map((item) {
    if (item is! Map) throw const FormatException('Expected object');
    return Map<String, dynamic>.from(item);
  }).toList(growable: false);
}

bool _isUncertainOption(String option) =>
    option.contains('不确定') || option.contains('不清楚');

void _ensureUncertainExit(List<String> options, String label,
    {required int max}) {
  if (options.any(_isUncertainOption)) return;
  if (options.length >= max) {
    options[options.length - 1] = label;
  } else {
    options.add(label);
  }
}
