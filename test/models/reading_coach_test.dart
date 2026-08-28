import 'package:anx_reader/models/reading_coach.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('inspection guide survives database serialization', () {
    final guide = InspectionReadingGuide(
      bookId: 42,
      status: InspectionGuideStatus.completed,
      topicChoice: '核心问题',
      goalChoice: '学习知识',
      report: const {'summary': '结构概览'},
      answers: const {
        'whole': ActiveReadingAnswer(
          questionId: 'whole',
          selected: ['核心问题'],
          updatedAt: 100,
        ),
      },
      updatedAt: 200,
    );

    final restored = InspectionReadingGuide.fromDb(guide.toDb());
    expect(restored.bookId, 42);
    expect(restored.status, InspectionGuideStatus.completed);
    expect(restored.report?['summary'], '结构概览');
    expect(restored.answers['whole']?.selected, ['核心问题']);
  });

  test('chapter quiz survives database serialization', () {
    final quiz = ChapterQuiz(
      id: 'quiz-1',
      bookId: 42,
      chapterHref: 'chapter.xhtml',
      questions: const [
        {
          'id': 'q1',
          'question': '主旨？',
          'options': ['A', 'B', '暂不确定'],
          'correct': ['A'],
          'multiple': false,
        },
      ],
      answers: const {
        'q1': ['A'],
      },
      mastery: ReadingMasteryLevel.solid,
      completed: true,
      updatedAt: 300,
    );

    final restored = ChapterQuiz.fromDb(quiz.toDb());
    expect(restored.questions.single['id'], 'q1');
    expect(restored.answers['q1'], ['A']);
    expect(restored.mastery, ReadingMasteryLevel.solid);
    expect(restored.completed, isTrue);
  });
}
