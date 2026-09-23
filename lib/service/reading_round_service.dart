import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/reading_round.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/models/book.dart';

/// 多刷阅读统计：轮次管理服务
///
/// 流程：
/// 1. 阅读中：时长按 (book_id, date, round) 入库，并累加到 tb_reading_rounds
/// 2. 用户点击【完成本轮】：
///    - 当前轮记录写入结束快照（end_time / end_percentage / total_reading_time）
///    - book.currentRound + 1，阅读进度与位置归零
///    - 新建下一轮记录（status=reading, start_percentage=0）
class ReadingRoundService {
  ReadingRoundService._();

  /// 完成当前轮，开启下一轮；返回更新后的 [Book]
  static Future<Book> finishCurrentRound(Book book) async {
    // 以数据库中的最新状态为准：调用方可能持有较早加载的 Book 实例
    // （例如详情页与书架对象不同步），若直接采信会导致轮次号/进度错乱。
    Book fresh = book;
    try {
      fresh = await bookDao.selectBookById(book.id);
    } catch (_) {
      // 查询失败时退回传入实例
    }

    final currentRound = fresh.currentRound;

    // 1. 确保当前轮记录存在（可能从未在详情页打开过）
    await readingRoundDao.ensureCurrentRound(
      bookId: fresh.id,
      roundNumber: currentRound,
      startPercentage: fresh.readingPercentage,
    );

    // 2. 本轮累计时长（按 tb_reading_time 实际记录汇总）
    final totalTime =
        await readingTimeDao.selectTotalReadingTimeByBookAndRound(
            fresh.id, currentRound);

    // 3. 写入当前轮结束快照
    //    仅结束"轮次号与当前轮一致"的进行中记录，避免误结束其他轮次
    final current = await readingRoundDao.getCurrentRound(fresh.id);
    if (current != null &&
        !current.isFinished &&
        current.roundNumber == currentRound) {
      await readingRoundDao.finishRound(
        current.id!,
        endPercentage: fresh.readingPercentage,
        totalReadingTime: totalTime,
      );
    }

    // 4. 开启下一轮：轮次 +1，进度/位置归零，新建记录
    final nextRound = currentRound + 1;
    await readingRoundDao.createRound(
      bookId: fresh.id,
      roundNumber: nextRound,
      startPercentage: 0,
    );

    final updated = fresh.copyWith(
      currentRound: nextRound,
      lastReadPosition: '',
      readingPercentage: 0,
    );
    // 轮次号单独写入（Book.toMap 不再包含 current_round，避免被旧实例覆盖）
    await bookDao.updateCurrentRound(fresh.id, nextRound);
    await bookDao.updateBook(updated);
    return updated;
  }

  /// 撤销最近一次【完成本轮】（误触保护）：
  /// 删除进行中的新轮记录，轮次号回退，并尽量恢复上一轮结束时的进度。
  /// 返回更新后的 [Book]；无可回退时返回原 [book]。
  static Future<Book> undoLastRound(Book book) async {
    // 同 finishCurrentRound：以数据库最新状态为准
    Book fresh = book;
    try {
      fresh = await bookDao.selectBookById(book.id);
    } catch (_) {
      // 查询失败时退回传入实例
    }

    if (fresh.currentRound <= 1) {
      return fresh;
    }

    final previousRound = fresh.currentRound - 1;
    final rounds = await readingRoundDao.selectRoundsByBookId(fresh.id);

    // 找到上一轮的完成快照，用于恢复进度
    double restoredPercentage = 0;
    for (final r in rounds) {
      if (r.roundNumber == previousRound && r.isFinished) {
        restoredPercentage = r.endPercentage;
        break;
      }
    }

    // 删除当前进行中的轮次记录（仅删除轮次号匹配的那条，避免误删）
    final current = await readingRoundDao.getCurrentRound(fresh.id);
    if (current != null &&
        current.id != null &&
        current.roundNumber == fresh.currentRound) {
      await readingRoundDao.delete(ReadingRoundDao.table,
          where: 'id = ?', whereArgs: [current.id]);
    }

    final updated = fresh.copyWith(
      currentRound: previousRound,
      readingPercentage: restoredPercentage,
      lastReadPosition: '',
    );
    // 轮次号单独写入（同 finishCurrentRound 的原因）
    await bookDao.updateCurrentRound(fresh.id, previousRound);
    await bookDao.updateBook(updated);
    return updated;
  }
}
