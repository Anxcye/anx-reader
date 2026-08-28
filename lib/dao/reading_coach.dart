import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:sqflite/sqflite.dart';

class ReadingCoachDao extends BaseDao {
  ReadingCoachDao({super.databaseProvider});

  Future<InspectionReadingGuide?> selectGuide(int bookId) => querySingle(
        'tb_reading_guides',
        mapper: InspectionReadingGuide.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
      );

  Future<void> saveGuide(InspectionReadingGuide guide) async {
    await insert(
      'tb_reading_guides',
      guide.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ChapterQuiz>> selectQuizzes(int bookId) => queryList(
        'tb_reading_quizzes',
        mapper: ChapterQuiz.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'updated_at DESC',
      );

  Future<void> saveQuiz(ChapterQuiz quiz) async {
    await insert(
      'tb_reading_quizzes',
      quiz.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<ReadingDifficulty>> selectDifficulties(int bookId) => queryList(
        'tb_reading_difficulties',
        mapper: ReadingDifficulty.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'updated_at DESC',
      );

  Future<ReadingDifficulty?> findDifficulty({
    required int bookId,
    required String cfi,
    required String text,
  }) =>
      querySingle(
        'tb_reading_difficulties',
        mapper: ReadingDifficulty.fromDb,
        where: 'book_id = ? AND cfi = ? AND selected_text = ?',
        whereArgs: [bookId, cfi, text],
      );

  Future<void> saveDifficulty(ReadingDifficulty difficulty) async {
    await insert(
      'tb_reading_difficulties',
      difficulty.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }
}

final readingCoachDao = ReadingCoachDao();
