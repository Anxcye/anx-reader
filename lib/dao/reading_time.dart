import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/reading_round.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/enums/sync_trigger.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/providers/sync.dart';

class ReadingTimeDao extends BaseDao {
  ReadingTimeDao();

  static const String table = 'tb_reading_time';

  Future<void> insertReadingTime(
    ReadingTime readingTime, {
    DateTime? startedAt,
  }) async {
    final db = await database;
    final resolvedDay = _resolveDayString(readingTime, startedAt);

    readingTime.date ??= resolvedDay;

    await db.transaction((txn) async {
      final existing = await txn.rawQuery(
        'SELECT id, reading_time FROM $table '
        'WHERE book_id = ? AND DATE(date) = DATE(?) AND round = ? LIMIT 1',
        [readingTime.bookId, resolvedDay, readingTime.round],
      );

      if (existing.isNotEmpty) {
        final current = existing.first['reading_time'] as int? ?? 0;
        await txn.update(
          table,
          {
            'reading_time': current + readingTime.readingTime,
            // keep legacy date value unchanged to avoid churn
          },
          where: 'id = ?',
          whereArgs: [existing.first['id']],
        );
      } else {
        await txn.insert(
          table,
          {
            'book_id': readingTime.bookId,
            'date': resolvedDay,
            'reading_time': readingTime.readingTime,
            'round': readingTime.round,
          },
        );
      }
    });

    // 同步把本次时长累加到该书进行中的轮次（多刷统计）
    if (readingTime.readingTime > 0) {
      await readingRoundDao.accumulateReadingTime(
        bookId: readingTime.bookId,
        roundNumber: readingTime.round,
        seconds: readingTime.readingTime,
      );
    }
  }

  Future<void> insertReadingSession({
    required int bookId,
    required int readingTime,
    DateTime? startedAt,
    int round = 1,
  }) async {
    final session = ReadingTime(
      bookId: bookId,
      readingTime: readingTime,
      date: startedAt?.toIso8601String(),
      round: round,
    );

    await insertReadingTime(session, startedAt: startedAt);
  }

  String _resolveDayString(ReadingTime readingTime, DateTime? startedAt) {
    final fromModel = readingTime.startedAt;
    if (fromModel != null) {
      return _dayKey(fromModel);
    }

    if (startedAt != null) {
      return _dayKey(startedAt);
    }

    final raw = readingTime.date;
    if (raw != null && raw.length >= 10) {
      return raw.substring(0, 10);
    }

    return _dayKey(DateTime.now());
  }

  String _dayKey(DateTime dateTime) =>
      dateTime.toIso8601String().substring(0, 10);

  Future<List<ReadingTime>> selectAllReadingTime() async {
    return queryList(
      table,
      mapper: ReadingTime.fromDb,
      orderBy: 'datetime(date) DESC, id DESC',
    );
  }

  Future<int> selectTotalReadingTime() async {
    final result = await rawQuerySingle(
      'SELECT SUM(reading_time) AS total_sum FROM $table',
      mapper: (row) => row['total_sum'] as int? ?? 0,
    );
    return result ?? 0;
  }

  Future<int> selectTotalNumberOfBook() async {
    final result = await rawQuerySingle(
      'SELECT COUNT(DISTINCT book_id) AS total_count FROM $table',
      mapper: (row) => row['total_count'] as int? ?? 0,
    );
    return result ?? 0;
  }

  Future<int> selectTotalNumberOfDate() async {
    final result = await rawQuerySingle(
      'SELECT COUNT(DISTINCT DATE(date)) AS total_count FROM $table',
      mapper: (row) => row['total_count'] as int? ?? 0,
    );
    return result ?? 0;
  }

  Future<int> selectTotalNumberOfNotes() async {
    final result = await rawQuerySingle(
      'SELECT COUNT(*) AS total_count FROM tb_notes',
      mapper: (row) => row['total_count'] as int? ?? 0,
    );
    return result ?? 0;
  }

  Future<List<int>> selectReadingTimeOfWeek(DateTime dateTime) async {
    final start = dateTime.subtract(Duration(days: dateTime.weekday - 1));
    final end = start.add(const Duration(days: 6));
    final rows = await rawQueryList(
      '''
      SELECT DATE(date) AS day, SUM(reading_time) AS total_sum 
      FROM $table 
      WHERE DATE(date) BETWEEN DATE(?) AND DATE(?) 
      GROUP BY day
      ''',
      arguments: [
        start.toIso8601String().substring(0, 10),
        end.toIso8601String().substring(0, 10),
      ],
      mapper: (row) => row,
    );

    final totals = {
      for (final row in rows)
        row['day'] as String: row['total_sum'] as int? ?? 0,
    };

    return List<int>.generate(7, (index) {
      final day = start.add(Duration(days: index));
      final key = day.toIso8601String().substring(0, 10);
      return totals[key] ?? 0;
    });
  }

  Future<List<int>> selectReadingTimeOfMonth(DateTime dateTime) async {
    final firstDay = DateTime(dateTime.year, dateTime.month, 1);
    final lastDay = DateTime(dateTime.year, dateTime.month + 1, 0);

    final rows = await rawQueryList(
      '''
      SELECT DATE(date) AS day, SUM(reading_time) AS total_sum 
      FROM $table 
      WHERE DATE(date) BETWEEN DATE(?) AND DATE(?) 
      GROUP BY day
      ''',
      arguments: [
        firstDay.toIso8601String().substring(0, 10),
        lastDay.toIso8601String().substring(0, 10),
      ],
      mapper: (row) => row,
    );

    final totals = {
      for (final row in rows)
        row['day'] as String: row['total_sum'] as int? ?? 0,
    };

    final daysInMonth = lastDay.day;
    return List<int>.generate(daysInMonth, (index) {
      final day = firstDay.add(Duration(days: index));
      final key = day.toIso8601String().substring(0, 10);
      return totals[key] ?? 0;
    });
  }

  Future<List<int>> selectReadingTimeOfYear(DateTime dateTime) async {
    final yearStart = DateTime(dateTime.year, 1, 1);
    final yearEnd = DateTime(dateTime.year, 12, 31);

    final rows = await rawQueryList(
      '''
      SELECT strftime('%Y-%m', date) AS month, SUM(reading_time) AS total_sum 
      FROM $table 
      WHERE DATE(date) BETWEEN DATE(?) AND DATE(?) 
      GROUP BY month
      ''',
      arguments: [
        yearStart.toIso8601String().substring(0, 10),
        yearEnd.toIso8601String().substring(0, 10),
      ],
      mapper: (row) => row,
    );

    final totals = {
      for (final row in rows)
        row['month'] as String: row['total_sum'] as int? ?? 0,
    };

    return List<int>.generate(12, (index) {
      final monthKey = DateTime(dateTime.year, index + 1, 1)
          .toIso8601String()
          .substring(0, 7);
      return totals[monthKey] ?? 0;
    });
  }

  Future<List<ReadingTime>> selectReadingTimeByBookId(int bookId) {
    return queryList(
      table,
      mapper: ReadingTime.fromDb,
      where: 'book_id = ?',
      whereArgs: [bookId],
      orderBy: 'datetime(date) DESC, id DESC',
    );
  }

  /// 某本书**按日期汇总**的阅读时长（把该书当天的所有轮次合并成一条）。
  ///
  /// 多刷功能使 tb_reading_time 的聚合键变为 (书, 日期, 轮次)，同一天读过
  /// 多轮就会有多条记录；书籍详情页的时长列表应按日期合并显示，避免出现
  /// 重复日期。逐轮明细由 tb_reading_rounds / 轮次卡片负责展示。
  Future<List<ReadingTime>> selectDailyTotalReadingTimeByBookId(int bookId) {
    return rawQueryList(
      '''
      SELECT DATE(date) AS day, SUM(reading_time) AS total_time
      FROM $table
      WHERE book_id = ?
      GROUP BY day
      ORDER BY day DESC
      ''',
      arguments: [bookId],
      mapper: (row) => ReadingTime(
        bookId: bookId,
        date: row['day'] as String?,
        readingTime: row['total_time'] as int? ?? 0,
      ),
    );
  }

  Future<List<ReadingTime>> queryReadingHistory({
    int? bookId,
    DateTime? from,
    DateTime? to,
    int? limit,
  }) async {
    final where = <String>[];
    final whereArgs = <Object?>[];

    if (bookId != null) {
      where.add('book_id = ?');
      whereArgs.add(bookId);
    }

    String? toDateTimeString(DateTime? date) => date?.toIso8601String();

    final fromStr = toDateTimeString(from);
    final toStr = toDateTimeString(to);

    if (fromStr != null) {
      where.add('datetime(date) >= datetime(?)');
      whereArgs.add(fromStr);
    }

    if (toStr != null) {
      where.add('datetime(date) <= datetime(?)');
      whereArgs.add(toStr);
    }

    return queryList(
      table,
      mapper: ReadingTime.fromDb,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: where.isEmpty ? null : whereArgs,
      orderBy: 'datetime(date) DESC, id DESC',
      limit: limit,
    );
  }

  Future<List<Map<int, int>>> selectThisWeekBooks() async {
    final monday =
        DateTime.now().subtract(Duration(days: DateTime.now().weekday - 1));
    final rows = await rawQueryList(
      '''
      SELECT book_id, SUM(reading_time) AS total_sum 
      FROM $table 
      WHERE DATE(date) >= DATE(?) 
      GROUP BY book_id 
      ORDER BY total_sum DESC
      ''',
      arguments: [monday.toIso8601String().substring(0, 10)],
      mapper: (row) => {
        (row['book_id'] as int?) ?? 0: row['total_sum'] as int? ?? 0,
      },
    );
    return rows;
  }

  Future<int> selectTotalReadingTimeByBookId(int bookId) async {
    final total = await rawQuerySingle(
      'SELECT SUM(reading_time) AS total_sum FROM $table WHERE book_id = ?',
      arguments: [bookId],
      mapper: (row) => row['total_sum'] as int? ?? 0,
    );
    return total ?? 0;
  }

  /// 某本书某一轮次的累计阅读时长（秒）
  Future<int> selectTotalReadingTimeByBookAndRound(
      int bookId, int round) async {
    final total = await rawQuerySingle(
      'SELECT SUM(reading_time) AS total_sum FROM $table '
      'WHERE book_id = ? AND round = ?',
      arguments: [bookId, round],
      mapper: (row) => row['total_sum'] as int? ?? 0,
    );
    return total ?? 0;
  }

  /// 某本书某一轮次的阅读记录明细
  Future<List<ReadingTime>> selectReadingTimeByBookAndRound(
      int bookId, int round) {
    return queryList(
      table,
      mapper: ReadingTime.fromDb,
      where: 'book_id = ? AND round = ?',
      whereArgs: [bookId, round],
      orderBy: 'datetime(date) DESC, id DESC',
    );
  }

  Future<List<Map<Book, int>>> selectBookReadingTimeOfDay(DateTime date) async {
    final rows = await _aggregateByBook(
      where: 'DATE(date) = DATE(?)',
      whereArgs: [date.toIso8601String().substring(0, 10)],
    );
    return _attachBooks(rows);
  }

  Future<List<Map<Book, int>>> selectBookReadingTimeOfWeek(
      DateTime date) async {
    final start = date.subtract(Duration(days: date.weekday - 1));
    final end = start.add(const Duration(days: 6));
    final rows = await _aggregateByBook(
      where: 'DATE(date) BETWEEN DATE(?) AND DATE(?)',
      whereArgs: [
        start.toIso8601String().substring(0, 10),
        end.toIso8601String().substring(0, 10),
      ],
    );
    return _attachBooks(rows);
  }

  Future<List<Map<Book, int>>> selectBookReadingTimeOfMonth(
      DateTime date) async {
    final start = DateTime(date.year, date.month, 1);
    final end = DateTime(date.year, date.month + 1, 0);
    final rows = await _aggregateByBook(
      where: 'DATE(date) BETWEEN DATE(?) AND DATE(?)',
      whereArgs: [
        start.toIso8601String().substring(0, 10),
        end.toIso8601String().substring(0, 10),
      ],
    );
    return _attachBooks(rows);
  }

  Future<List<Map<Book, int>>> selectBookReadingTimeOfYear(
      DateTime date) async {
    final start = DateTime(date.year, 1, 1);
    final end = DateTime(date.year, 12, 31);
    final rows = await _aggregateByBook(
      where: 'DATE(date) BETWEEN DATE(?) AND DATE(?)',
      whereArgs: [
        start.toIso8601String().substring(0, 10),
        end.toIso8601String().substring(0, 10),
      ],
    );
    return _attachBooks(rows);
  }

  Future<Map<DateTime, int>> selectAllReadingTimeGroupByDay() async {
    final rows = await rawQueryList(
      '''
      SELECT DATE(date) AS day, SUM(reading_time) AS total_time 
      FROM $table 
      GROUP BY day 
      ORDER BY day ASC
      ''',
      mapper: (row) => row,
    );

    final result = <DateTime, int>{};
    for (final row in rows) {
      final date = DateTime.parse(row['day'] as String);
      result[date] = row['total_time'] as int? ?? 0;
    }
    return result;
  }

  Future<List<Map<Book, int>>> selectBookReadingTimeOfAll() async {
    final rows = await _aggregateByBook();
    return _attachBooks(rows);
  }

  Future<Map<String, dynamic>?> selectLatestReadingRecord() async {
    return await rawQuerySingle(
      '''
      SELECT book_id, date, reading_time 
      FROM $table 
      ORDER BY datetime(date) DESC, id DESC 
      LIMIT 1
      ''',
      mapper: (row) => row,
    );
  }

  Future<void> deleteReadingTimeByBookId(List<int> bookIds) async {
    if (bookIds.isEmpty) return;

    final placeholders = List.filled(bookIds.length, '?').join(',');
    await delete(
      table,
      where: 'book_id IN ($placeholders)',
      whereArgs: bookIds,
    );

    Sync().syncData(SyncDirection.both, null, trigger: SyncTrigger.auto);
  }

  Future<List<Map<String, dynamic>>> _aggregateByBook({
    String? where,
    List<Object?>? whereArgs,
  }) async {
    final db = await database;
    return db.rawQuery(
      '''
      SELECT book_id, SUM(reading_time) AS total_time 
      FROM $table 
      ${where != null ? 'WHERE $where' : ''} 
      GROUP BY book_id 
      ORDER BY total_time DESC
      ''',
      whereArgs,
    );
  }

  Future<List<Map<Book, int>>> _attachBooks(
      List<Map<String, dynamic>> rows) async {
    final ids = rows
        .map((row) => row['book_id'] as int?)
        .whereType<int>()
        .toSet()
        .toList();
    if (ids.isEmpty) {
      return const [];
    }

    final books = await bookDao.selectBooksByIds(ids);
    final bookMap = {for (final book in books) book.id: book};

    final result = <Map<Book, int>>[];
    for (final row in rows) {
      final bookId = row['book_id'] as int?;
      if (bookId == null) continue;
      final book = bookMap[bookId];
      if (book == null) continue;
      result.add({book: row['total_time'] as int? ?? 0});
    }
    return result;
  }

  Future<List<Map<String, dynamic>>> selectBookDailyReadingTime({
    required int bookId,
    required int days,
  }) async {
    final startDate = DateTime.now().subtract(Duration(days: days - 1));

    return rawQueryList(
      '''
      SELECT DATE(date) as day, SUM(reading_time) as total_time
      FROM $table
      WHERE book_id = ? AND DATE(date) >= DATE(?)
      GROUP BY day
      ORDER BY day ASC
      ''',
      arguments: [
        bookId,
        startDate.toIso8601String().substring(0, 10),
      ],
      mapper: (row) => {
        'day': row['day'] as String,
        'total_time': row['total_time'] as int? ?? 0,
      },
    );
  }

  Future<Map<DateTime, int>> selectDailyReadingTimeSince(
      DateTime startDate) async {
    final rows = await rawQueryList(
      '''
      SELECT DATE(date) as day, SUM(reading_time) as total_time
      FROM $table
      WHERE DATE(date) >= DATE(?)
      GROUP BY day
      ORDER BY day ASC
      ''',
      arguments: [startDate.toIso8601String().substring(0, 10)],
      mapper: (row) => row,
    );

    final result = <DateTime, int>{};
    for (final row in rows) {
      final day = row['day'] as String?;
      if (day == null) continue;
      result[DateTime.parse(day)] = row['total_time'] as int? ?? 0;
    }
    return result;
  }
}

final readingTimeDao = ReadingTimeDao();
