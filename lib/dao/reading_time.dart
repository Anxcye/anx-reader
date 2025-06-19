import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/providers/sync.dart';

import 'database.dart';

void insertReadingTime(ReadingTime readingTime) async {
  final db = await DBHelper().database;
  String today = DateTime.now().toString().substring(0, 10);
  final List<Map<String, dynamic>> maps = await db.query(
    'tb_reading_time',
    where: 'date = ? AND book_id = ?',
    whereArgs: [today, readingTime.bookId],
  );
  if (maps.isNotEmpty) {
    await db.update(
      'tb_reading_time',
      {
        'reading_time': maps[0]['reading_time'] + readingTime.readingTime,
      },
      where: 'id = ?',
      whereArgs: [maps[0]['id']],
    );
    return;
  } else {
    readingTime.date = today;
    await db.insert('tb_reading_time', readingTime.toMap());
  }
}

Future<List<ReadingTime>> selectAllReadingTime() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query('tb_reading_time');
  return List.generate(maps.length, (i) {
    return ReadingTime(
      id: maps[i]['id'],
      bookId: maps[i]['book_id'],
      date: maps[i]['date'],
      readingTime: maps[i]['reading_time'],
    );
  });
}

Future<int> selectTotalReadingTime() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db
      .rawQuery('SELECT SUM(reading_time) AS total_sum FROM tb_reading_time');
  return maps[0]['total_sum'] ?? 0;
}

Future<int> selectTotalNumberOfBook() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT COUNT(DISTINCT book_id) AS total_count FROM tb_reading_time');
  return maps[0]['total_count'];
}

Future<int> selectTotalNumberOfDate() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT COUNT(DISTINCT date) AS total_count FROM tb_reading_time');
  return maps[0]['total_count'];
}

Future<int> selectTotalNumberOfNotes() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps =
      await db.rawQuery('SELECT COUNT(*) AS total_count FROM tb_notes');
  return maps[0]['total_count'];
}

Future<List<int>> selectReadingTimeOfWeek(DateTime dateTime) async {
  final db = await DBHelper().database;

  List<int> result = List.generate(7, (i) => 0);

  for (int i = 0; i < 7; i++) {
    DateTime day = dateTime.subtract(Duration(days: dateTime.weekday - 1 - i));
    String dayString = day.toString().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT SUM(reading_time) AS total_sum FROM tb_reading_time WHERE date = ?',
        [dayString]);

    if (maps.isNotEmpty && maps[0]['total_sum'] != null) {
      result[i] = maps[0]['total_sum'];
    }
  }
  return result;
}

Future<List<int>> selectReadingTimeOfMonth(DateTime dateTime) async {
  final db = await DBHelper().database;

  int numberOfDays = DateTime(dateTime.year, dateTime.month + 1, 0).day;
  List<int> result = List.generate(numberOfDays, (i) => 0);

  for (int i = 0; i < numberOfDays; i++) {
    DateTime day = DateTime(dateTime.year, dateTime.month, i + 1);
    String dayString = day.toString().substring(0, 10);

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT SUM(reading_time) AS total_sum FROM tb_reading_time WHERE date = ?',
        [dayString]);

    if (maps.isNotEmpty && maps[0]['total_sum'] != null) {
      result[i] = maps[0]['total_sum'];
    }
  }
  return result;
}

Future<List<int>> selectReadingTimeOfYear(DateTime dateTime) async {
  final db = await DBHelper().database;

  List<int> result = List.generate(12, (i) => 0);

  for (int i = 0; i < 12; i++) {
    DateTime day = DateTime(dateTime.year, i + 1, 1);
    String dayString = day.toString().substring(0, 7);

    final List<Map<String, dynamic>> maps = await db.rawQuery(
        'SELECT SUM(reading_time) AS total_sum FROM tb_reading_time WHERE date LIKE ?',
        ['$dayString%']);

    if (maps.isNotEmpty && maps[0]['total_sum'] != null) {
      result[i] = maps[0]['total_sum'];
    }
  }
  return result;
}

Future<List<ReadingTime>> selectReadingTimeByBookId(int bookId) async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.query(
    'tb_reading_time',
    where: 'book_id = ?',
    whereArgs: [bookId],
  );
  return List.generate(maps.length, (i) {
    return ReadingTime(
      id: maps[i]['id'],
      bookId: maps[i]['book_id'],
      date: maps[i]['date'],
      readingTime: maps[i]['reading_time'],
    );
  });
}

Future<List<Map<int, int>>> selectThisWeekBooks() async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT book_id, SUM(reading_time) AS total_sum FROM tb_reading_time WHERE date >= ? GROUP BY book_id ORDER BY total_sum DESC',
      [
        DateTime.now()
            .subtract(Duration(days: DateTime.now().weekday - 1))
            .toString()
            .substring(0, 10)
      ]);

  return List.generate(maps.length, (i) {
    return {maps[i]['book_id']: maps[i]['total_sum']};
  });
}

Future<int> selectTotalReadingTimeByBookId(int bookId) async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT SUM(reading_time) AS total_sum FROM tb_reading_time WHERE book_id = ?',
      [bookId]);
  return maps[0]['total_sum'] ?? 0;
}

Future<List<Map<Book, int>>> selectBookReadingTimeOfDay(DateTime date) async {
  final db = await DBHelper().database;
  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT book_id, SUM(reading_time) as total_time FROM tb_reading_time WHERE date = ? GROUP BY book_id ORDER BY total_time DESC',
      [date.toString().substring(0, 10)]);

  List<Map<Book, int>> result = [];
  for (var map in maps) {
    final book = await selectBookById(map['book_id']);
    result.add({book: map['total_time']});
  }

  return result;
}

Future<List<Map<Book, int>>> selectBookReadingTimeOfWeek(DateTime date) async {
  final db = await DBHelper().database;
  final weekStart = date.subtract(Duration(days: date.weekday - 1));
  final weekEnd = weekStart.add(const Duration(days: 6));

  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT book_id, SUM(reading_time) as total_time FROM tb_reading_time WHERE date >= ? AND date <= ? GROUP BY book_id ORDER BY total_time DESC',
      [
        weekStart.toString().substring(0, 10),
        weekEnd.toString().substring(0, 10)
      ]);

  List<Map<Book, int>> result = [];
  for (var map in maps) {
    final book = await selectBookById(map['book_id']);
    result.add({book: map['total_time']});
  }

  return result;
}

Future<List<Map<Book, int>>> selectBookReadingTimeOfMonth(DateTime date) async {
  final db = await DBHelper().database;
  final monthStart = DateTime(date.year, date.month, 1);
  final monthEnd = DateTime(date.year, date.month + 1, 0);

  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT book_id, SUM(reading_time) as total_time FROM tb_reading_time WHERE date >= ? AND date <= ? GROUP BY book_id ORDER BY total_time DESC',
      [
        monthStart.toString().substring(0, 10),
        monthEnd.toString().substring(0, 10)
      ]);

  List<Map<Book, int>> result = [];
  for (var map in maps) {
    final book = await selectBookById(map['book_id']);
    result.add({book: map['total_time']});
  }

  return result;
}

Future<List<Map<Book, int>>> selectBookReadingTimeOfYear(DateTime date) async {
  final db = await DBHelper().database;
  final yearStart = DateTime(date.year, 1, 1);
  final yearEnd = DateTime(date.year, 12, 31);

  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT book_id, SUM(reading_time) as total_time FROM tb_reading_time WHERE date >= ? AND date <= ? GROUP BY book_id ORDER BY total_time DESC',
      [
        yearStart.toString().substring(0, 10),
        yearEnd.toString().substring(0, 10)
      ]);

  List<Map<Book, int>> result = [];
  for (var map in maps) {
    final book = await selectBookById(map['book_id']);
    result.add({book: map['total_time']});
  }

  return result;
}

Future<Map<DateTime, int>> selectAllReadingTimeGroupByDay() async {
  final db = await DBHelper().database;

  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT date, SUM(reading_time) as total_time FROM tb_reading_time GROUP BY date ORDER BY date ASC');

  Map<DateTime, int> result = {};
  for (var map in maps) {
    final date = DateTime.parse(map['date']);
    result[date] = map['total_time'];
  }

  return result;
}

Future<List<Map<Book, int>>> selectBookReadingTimeOfAll(DateTime date) async {
  final db = await DBHelper().database;

  final List<Map<String, dynamic>> maps = await db.rawQuery(
      'SELECT book_id, SUM(reading_time) as total_time FROM tb_reading_time GROUP BY book_id ORDER BY total_time DESC');

  List<Map<Book, int>> result = [];
  for (var map in maps) {
    final book = await selectBookById(map['book_id']);
    result.add({book: map['total_time']});
  }

  return result;
}

Future<void> deleteReadingTimeByBookId(List<int> bookIds) async {
  final db = await DBHelper().database;
  for (var bookId in bookIds) {
    await db
        .delete('tb_reading_time', where: 'book_id = ?', whereArgs: [bookId]);
  }
  Sync().syncData(SyncDirection.both, null);
}
