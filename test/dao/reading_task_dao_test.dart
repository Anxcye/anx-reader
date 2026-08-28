import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/dao/reading_task.dart';
import 'package:anx_reader/models/reading_task.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  test('durable task round-trips payload and checkpoint', () async {
    final db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    addTearDown(db.close);
    for (final statement in createReadingTasksSQL.split(';')) {
      if (statement.trim().isNotEmpty) await db.execute(statement);
    }
    final dao = ReadingTaskDao(databaseProvider: () async => db);
    final task = ReadingTask(
      id: 'task-1',
      type: 'fiction.backfill',
      bookId: 7,
      priority: ReadingTaskPriority.userInitiated,
      persistence: ReadingTaskPersistence.durable,
      status: ReadingTaskStatus.paused,
      payload: const {'fromProgress': .2},
      checkpoint: const {'completedChapters': 4},
      progress: .4,
      canPause: true,
      attempts: 1,
      createdAt: 10,
      updatedAt: 20,
    );

    await dao.save(task);
    final restored = await dao.loadRecoverable();

    expect(restored, hasLength(1));
    expect(restored.single.bookId, 7);
    expect(restored.single.payload, {'fromProgress': .2});
    expect(restored.single.checkpoint, {'completedChapters': 4});
    expect(restored.single.progress, .4);
  });
}
