import 'package:anx_reader/dao/reading_coach.dart';
import 'package:anx_reader/models/reading_coach.dart';

class ReadingCoachRepository {
  ReadingCoachRepository({ReadingCoachDao? dao})
      : _dao = dao ?? readingCoachDao;

  final ReadingCoachDao _dao;

  Future<InspectionReadingGuide> loadGuide(int bookId) async {
    return await _dao.selectGuide(bookId) ??
        InspectionReadingGuide(
          bookId: bookId,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        );
  }

  Future<void> saveGuide(InspectionReadingGuide guide) => _dao.saveGuide(guide);

  Future<List<ChapterQuiz>> loadQuizzes(int bookId) =>
      _dao.selectQuizzes(bookId);

  Future<void> saveQuiz(ChapterQuiz quiz) => _dao.saveQuiz(quiz);

  Future<List<ReadingDifficulty>> loadDifficulties(int bookId) =>
      _dao.selectDifficulties(bookId);

  Future<ReadingDifficulty> saveDifficulty(ReadingDifficulty difficulty) async {
    final existing = await _dao.findDifficulty(
      bookId: difficulty.bookId,
      cfi: difficulty.cfi,
      text: difficulty.text,
    );
    if (existing != null) {
      if (existing.status == ReadingDifficultyStatus.resolved) {
        final reopened = existing.copyWith(
          status: ReadingDifficultyStatus.unresolved,
          updatedAt: difficulty.updatedAt,
        );
        await _dao.saveDifficulty(reopened);
        return reopened;
      }
      return existing;
    }
    await _dao.saveDifficulty(difficulty);
    return difficulty;
  }

  Future<void> updateDifficulty(ReadingDifficulty difficulty) =>
      _dao.saveDifficulty(difficulty);
}
