import 'package:anx_reader/service/ai/reading_coach_policy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('shouldCreateChapterQuiz', () {
    test('creates once after crossing 80 percent and changing chapter', () {
      expect(
        shouldCreateChapterQuiz(
          previousHref: 'chapter-1.xhtml',
          currentHref: 'chapter-2.xhtml',
          highestProgress: 0.8,
          existingChapterHrefs: const [],
        ),
        isTrue,
      );
    });

    test('rejects unknown progress, same chapter, and duplicate quiz', () {
      expect(
        shouldCreateChapterQuiz(
          previousHref: 'chapter-1.xhtml',
          currentHref: 'chapter-2.xhtml',
          highestProgress: 0,
          existingChapterHrefs: const [],
        ),
        isFalse,
      );
      expect(
        shouldCreateChapterQuiz(
          previousHref: 'chapter-1.xhtml',
          currentHref: 'chapter-1.xhtml',
          highestProgress: 1,
          existingChapterHrefs: const [],
        ),
        isFalse,
      );
      expect(
        shouldCreateChapterQuiz(
          previousHref: 'chapter-1.xhtml',
          currentHref: 'chapter-2.xhtml',
          highestProgress: 1,
          existingChapterHrefs: const ['chapter-1.xhtml'],
        ),
        isFalse,
      );
    });
  });

  group('parseChapterQuizResponse', () {
    const validQuestion =
        '{"id":"q1","question":"主旨？","options":["A","B","暂不确定"],"correct":["A"],"multiple":false}';

    test('accepts fenced JSON with three valid questions', () {
      final result = parseChapterQuizResponse(
        '```json\n[$validQuestion,'
        '${validQuestion.replaceFirst('q1', 'q2')},'
        '${validQuestion.replaceFirst('q1', 'q3')}]\n```',
      );
      expect(result, hasLength(3));
    });

    test('rejects missing uncertainty option and duplicate IDs', () {
      expect(
        () => parseChapterQuizResponse(
          '[$validQuestion,$validQuestion,$validQuestion]',
        ),
        throwsFormatException,
      );
      expect(
        () => parseChapterQuizResponse(
          '[${validQuestion.replaceAll(',"暂不确定"', '')},'
          '${validQuestion.replaceFirst('q1', 'q2')},'
          '${validQuestion.replaceFirst('q1', 'q3')}]',
        ),
        throwsFormatException,
      );
    });
  });
}
