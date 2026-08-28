import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/reading_task.dart';
import 'package:sqflite/sqflite.dart';

abstract interface class ReadingTaskStore {
  Future<void> save(ReadingTask task);
  Future<List<ReadingTask>> loadRecoverable();
  Future<void> deleteTask(String id);
}

class ReadingTaskDao extends BaseDao implements ReadingTaskStore {
  ReadingTaskDao({super.databaseProvider});

  @override
  Future<void> save(ReadingTask task) async {
    await insert(
      'tb_reading_tasks',
      task.toDb(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  @override
  Future<List<ReadingTask>> loadRecoverable() => queryList(
        'tb_reading_tasks',
        mapper: ReadingTask.fromDb,
        where: "persistence = 'durable' AND status IN (?, ?, ?, ?)",
        whereArgs: const ['queued', 'running', 'paused', 'failed'],
        orderBy: 'priority DESC, created_at ASC',
      );

  @override
  Future<void> deleteTask(String id) async {
    await super.delete('tb_reading_tasks', where: 'id = ?', whereArgs: [id]);
  }
}

final readingTaskDao = ReadingTaskDao();
