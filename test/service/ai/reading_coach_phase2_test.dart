import 'dart:convert';

import 'package:anx_reader/service/ai/reading_coach_phase2.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('representative chapters cover beginning, middle, and end', () {
    final indexes = representativeChapterIndexes(20);
    expect(indexes, hasLength(6));
    expect(indexes.take(2), [0, 1]);
    expect(indexes.last, 19);
    expect(indexes.toSet(), hasLength(indexes.length));
  });

  test('chapter samples retain bounded head and tail', () {
    final text = List.generate(5000, (index) => index % 10).join();
    final sample = boundedChapterSample(text);
    expect(sample.length, lessThanOrEqualTo(3003));
    expect(sample.startsWith(text.substring(0, 2000)), isTrue);
    expect(sample.endsWith(text.substring(4000)), isTrue);
  });

  test('personalized guide parser adds uncertainty exits', () {
    final response = jsonEncode({
      'bookType': '历史',
      'coreQuestion': '制度如何变化？',
      'topics': ['制度变化', '人物选择', '时代背景'],
      'structure': ['提出背景', '按时期展开'],
      'keyChapters': [
        {'title': '第一章', 'href': 'c1', 'reason': '建立背景'},
      ],
      'plan': ['先读总论', '再读关键章节'],
      'questionOptions': {
        for (final id in activeReadingQuestionIds)
          id: ['$id 选项一', '$id 选项二', '$id 选项三'],
      },
    });
    final result = parsePersonalizedGuideResponse(response);
    expect(result['topics'], contains('我还不确定'));
    final questions = result['questionOptions'] as Map<String, dynamic>;
    expect(questions['whole'], contains('暂不确定'));
  });

  test('synthesis parser rejects underspecified output', () {
    expect(
      () => parseReadingSynthesisResponse('{"summary":"too short"}'),
      throwsFormatException,
    );
  });

  test('review queue uses mastery-specific intervals', () {
    const day = Duration.millisecondsPerDay;
    const now = 10 * day;
    ChapterQuiz quiz(String id, ReadingMasteryLevel mastery, int age) =>
        ChapterQuiz(
          id: id,
          bookId: 1,
          chapterHref: id,
          mastery: mastery,
          completed: true,
          updatedAt: now - age,
        );
    final due = dueReviewQuizzes([
      quiz('needs-review', ReadingMasteryLevel.needsReview, day),
      quiz('developing', ReadingMasteryLevel.developing, 2 * day),
      quiz('solid', ReadingMasteryLevel.solid, 7 * day),
    ], now: now);
    expect(due.map((quiz) => quiz.id), ['needs-review', 'solid']);
  });
}
