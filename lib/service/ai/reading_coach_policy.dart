import 'dart:convert';

bool shouldCreateChapterQuiz({
  required String previousHref,
  required String currentHref,
  required double highestProgress,
  required Iterable<String> existingChapterHrefs,
}) {
  return previousHref.isNotEmpty &&
      currentHref.isNotEmpty &&
      previousHref != currentHref &&
      highestProgress >= 0.8 &&
      !existingChapterHrefs.contains(previousHref);
}

List<Map<String, dynamic>> parseChapterQuizResponse(String response) {
  final cleaned = response
      .replaceFirst(RegExp(r'^\s*```(?:json)?', caseSensitive: false), '')
      .replaceFirst(RegExp(r'```\s*$'), '')
      .trim();
  final decoded = jsonDecode(cleaned);
  if (decoded is! List || decoded.length != 3) {
    throw const FormatException('Expected exactly three questions');
  }
  final questions = decoded.map((value) {
    if (value is! Map) {
      throw const FormatException('Question must be an object');
    }
    final item = Map<String, dynamic>.from(value);
    final id = item['id'];
    final question = item['question'];
    final options = item['options'];
    final correct = item['correct'];
    final multiple = item['multiple'];
    if (id is! String ||
        id.trim().isEmpty ||
        question is! String ||
        question.trim().isEmpty ||
        options is! List ||
        options.length < 3 ||
        options.length > 5 ||
        !options
            .every((option) => option is String && option.trim().isNotEmpty) ||
        !options.contains('暂不确定') ||
        correct is! List ||
        correct.isEmpty ||
        !correct.every((answer) => options.contains(answer)) ||
        multiple is! bool) {
      throw const FormatException('Invalid question schema');
    }
    return item;
  }).toList(growable: false);
  if (questions.map((item) => item['id']).toSet().length != 3) {
    throw const FormatException('Question IDs must be unique');
  }
  return questions;
}
