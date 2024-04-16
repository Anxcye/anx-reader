import '../models/reading_time.dart';
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
