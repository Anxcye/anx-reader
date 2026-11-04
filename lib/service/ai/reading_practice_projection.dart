import 'package:anx_reader/models/reading_coach.dart';

abstract final class ReadingPracticeProjection {
  static bool _visible(Object? source, Object? boundary, double progress) =>
      source is num &&
      boundary is num &&
      source.isFinite &&
      boundary.isFinite &&
      source >= 0 &&
      boundary >= source &&
      boundary <= 1 &&
      boundary <= progress + .000001;

  static InspectionReadingGuide visibleGuide(
      InspectionReadingGuide guide, double progress) {
    final report = guide.report;
    Map<String, dynamic>? visible;
    if (report != null &&
        _visible(report['sourceProgress'], report['visibleFromProgress'],
            progress)) {
      visible = report;
    } else if (report != null &&
        _visible(report['synthesisSourceProgress'],
            report['synthesisVisibleFromProgress'], progress)) {
      visible = {
        for (final key in const [
          'synthesis',
          'synthesisGeneratedAt',
          'synthesisSourceProgress',
          'synthesisVisibleFromProgress'
        ])
          if (report.containsKey(key)) key: report[key]
      };
    }
    return InspectionReadingGuide(
        bookId: guide.bookId,
        status: guide.status,
        topicChoice: guide.topicChoice,
        goalChoice: guide.goalChoice,
        note: guide.note,
        report: visible,
        answers: guide.answers,
        updatedAt: guide.updatedAt);
  }

  static bool quizVisible(ChapterQuiz quiz, double progress) =>
      quiz.questions.isNotEmpty &&
      quiz.questions.every((question) =>
          question['sourceChapterRef'] == quiz.chapterHref &&
          _visible(question['sourceProgress'], question['visibleFromProgress'],
              progress));
}
