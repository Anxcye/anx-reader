import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/service/ai/reading_practice_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
      'future guide is hidden while personal answers and safe synthesis remain',
      () {
    final guide = InspectionReadingGuide(
        bookId: 1,
        note: 'My note',
        updatedAt: 1,
        report: {
          'overview': 'Later material',
          'sourceProgress': 1,
          'visibleFromProgress': 1,
          'synthesis': 'What I have read',
          'synthesisSourceProgress': .3,
          'synthesisVisibleFromProgress': .3
        });
    final safe = ReadingPracticeProjection.visibleGuide(guide, .4);
    expect(safe.note, 'My note');
    expect(safe.report?['overview'], isNull);
    expect(safe.report?['synthesis'], 'What I have read');
    expect(ReadingPracticeProjection.visibleGuide(guide, .2).report, isNull);
    expect(ReadingPracticeProjection.visibleGuide(guide, 1).report?['overview'],
        'Later material');
    expect(
        ReadingPracticeProjection.visibleGuide(
                InspectionReadingGuide(
                    bookId: 1,
                    report: {'overview': 'Unknown scope'},
                    updatedAt: 1),
                .9)
            .report,
        isNull);
  });

  test('quiz visibility requires matching source chapter and valid boundaries',
      () {
    ChapterQuiz quiz(Map<String, dynamic> provenance) => ChapterQuiz(
        id: 'quiz',
        bookId: 1,
        chapterHref: 'chapter.xhtml',
        questions: [
          {'id': 'q1', 'question': 'Q', ...provenance}
        ],
        updatedAt: 1);
    expect(ReadingPracticeProjection.quizVisible(quiz({}), .8), isFalse);
    expect(
        ReadingPracticeProjection.quizVisible(
            quiz({
              'sourceProgress': .2,
              'visibleFromProgress': .3,
              'sourceChapterRef': 'chapter.xhtml'
            }),
            .4),
        isTrue);
    expect(
        ReadingPracticeProjection.quizVisible(
            quiz({
              'sourceProgress': 1,
              'visibleFromProgress': 1,
              'sourceChapterRef': 'chapter.xhtml',
              'authorizedChapterProcessing': true
            }),
            .4),
        isFalse);
    expect(
        ReadingPracticeProjection.quizVisible(
            quiz({
              'sourceProgress': .2,
              'visibleFromProgress': .3,
              'sourceChapterRef': 'other.xhtml'
            }),
            .4),
        isFalse);
  });
}
