import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/reading_round.dart';

class ReadingRoundDao extends BaseDao {
  ReadingRoundDao();

  static const String table = 'tb_reading_rounds';

  /// 查询某本书的全部轮次（按轮次号升序）
  Future<List<ReadingRound>> selectRoundsByBookId(int bookId) {
    return queryList(
      table,
      mapper: ReadingRound.fromDb,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'round_number ASC',
    );
  }

  /// 查询某本书当前进行中的轮次
  Future<ReadingRound?> getCurrentRound(int bookId) {
    return querySingle(
      table,
      mapper: ReadingRound.fromDb,
      where: "book_id = ? AND status = ?",
      whereArgs: [bookId, ReadingRound.statusReading],
      orderBy: 'round_number DESC',
    );
  }

  /// 新建一轮（status = reading）
  Future<int> createRound({
    required int bookId,
    required int roundNumber,
    double startPercentage = 0,
    String? startTime,
  }) async {
    final now = DateTime.now().toIso8601String();
    return insert(table, {
      'book_id': bookId,
      'round_number': roundNumber,
      'status': ReadingRound.statusReading,
      'start_time': startTime ?? now,
      'start_percentage': startPercentage,
      'end_percentage': 0,
      'total_reading_time': 0,
      'create_time': now,
      'update_time': now,
    });
  }

  /// 完成一轮：写入结束快照
  Future<void> finishRound(
    int roundId, {
    required double endPercentage,
    required int totalReadingTime,
  }) async {
    await update(table, {
      'status': ReadingRound.statusFinished,
      'end_time': DateTime.now().toIso8601String(),
      'end_percentage': endPercentage,
      'total_reading_time': totalReadingTime,
      'update_time': DateTime.now().toIso8601String(),
    }, where: 'id = ?', whereArgs: [roundId]);
  }

  /// 阅读计时入库后，把时长累加到该书进行中的轮次（幂等：无记录时静默跳过）
  Future<void> accumulateReadingTime({
    required int bookId,
    required int roundNumber,
    required int seconds,
  }) async {
    final db = await database;
    await db.rawUpdate(
      'UPDATE $table SET total_reading_time = total_reading_time + ?, update_time = ? '
      'WHERE book_id = ? AND round_number = ? AND status = ?',
      [seconds, DateTime.now().toIso8601String(), bookId, roundNumber, ReadingRound.statusReading],
    );
  }

  /// 确保某本书的当前轮次记录存在（详情页/服务层打开时调用）
  Future<ReadingRound> ensureCurrentRound({
    required int bookId,
    required int roundNumber,
    double startPercentage = 0,
  }) async {
    final existing = await getCurrentRound(bookId);
    if (existing != null) {
      return existing;
    }
    final id = await createRound(
      bookId: bookId,
      roundNumber: roundNumber,
      startPercentage: startPercentage,
    );
    return (await querySingle(
      table,
      mapper: ReadingRound.fromDb,
      where: 'id = ?',
      whereArgs: [id],
    ))!;
  }
}

final readingRoundDao = ReadingRoundDao();
