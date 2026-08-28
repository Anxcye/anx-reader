import 'package:anx_reader/dao/database.dart';
import 'package:sqflite/sqflite.dart';

typedef AiSessionDatabaseProvider = Future<Database> Function();

class AiSessionDao {
  AiSessionDao({AiSessionDatabaseProvider? databaseProvider})
      : _databaseProvider = databaseProvider ?? _defaultDatabaseProvider;

  static const String table = 'tb_ai_sessions';

  final AiSessionDatabaseProvider _databaseProvider;

  static Future<Database> _defaultDatabaseProvider() => DBHelper().database;

  Future<List<Map<String, Object?>>> selectAll() async {
    final db = await _databaseProvider();
    return db.query(table, orderBy: 'updatedAt DESC');
  }

  Future<void> upsert(
    Map<String, Object?> values, {
    int? maxCount,
  }) async {
    final db = await _databaseProvider();
    await db.transaction((txn) async {
      await txn.insert(
        table,
        values,
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      if (maxCount != null && maxCount > 0) {
        await txn.rawDelete(
          '''
          DELETE FROM $table
          WHERE id NOT IN (
            SELECT id FROM $table ORDER BY updatedAt DESC LIMIT ?
          )
          ''',
          [maxCount],
        );
      }
    });
  }

  Future<void> insertAllIfAbsent(
    List<Map<String, Object?>> sessions,
  ) async {
    if (sessions.isEmpty) return;

    final db = await _databaseProvider();
    await db.transaction((txn) async {
      for (final session in sessions) {
        await txn.insert(
          table,
          session,
          conflictAlgorithm: ConflictAlgorithm.ignore,
        );
      }
    });
  }

  Future<int> remove(String id) async {
    final db = await _databaseProvider();
    return db.delete(table, where: 'id = ?', whereArgs: [id]);
  }

  Future<int> clear() async {
    final db = await _databaseProvider();
    return db.delete(table);
  }
}

final aiSessionDao = AiSessionDao();
