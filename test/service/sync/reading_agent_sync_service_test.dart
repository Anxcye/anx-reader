import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/dao/reading_agent_sync.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_agent_sync.dart';
import 'package:anx_reader/service/sync/reading_agent_sync_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();

  late Database db;

  Future<void> executeScript(String script) async {
    for (final statement in script
        .split(';')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)) {
      await db.execute(statement);
    }
  }

  setUp(() async {
    db = await databaseFactoryFfi.openDatabase(inMemoryDatabasePath);
    await db.execute('''
      CREATE TABLE tb_books (
        id INTEGER PRIMARY KEY, file_md5 TEXT, is_deleted INTEGER DEFAULT 0,
        last_read_position TEXT DEFAULT '', reading_percentage REAL DEFAULT 0
      )
    ''');
    await executeScript(createReadingDifficultiesSQL);
    await executeScript(createReadingAgentSQL);
    await executeScript(createReadingClosureSQL);
    await executeScript(createReadingExperienceModulesSQL);
    await executeScript(createReadingCoverageSQL);
    await executeScript(createReadingAgentSyncSQL);
    await db.insert('tb_books', {'id': 1, 'file_md5': 'book-md5'});
  });

  tearDown(() => db.close());

  test('preserves local position while deriving global farthest and coverage',
      () async {
    final service = ReadingAgentSyncService(deviceId: 'device-a');
    await db.insert('tb_book_device_positions', {
      'book_id': 1,
      'device_id': 'device-a',
      'cfi': 'local-52',
      'progress': .52,
      'updated_at': 100,
    });
    await db.insert('tb_book_reading_coverage', {
      'book_id': 1,
      'safe_knowledge_boundary': .52,
      'artifact_coverage_start': .52,
      'artifact_coverage_end': .52,
      'setup_status': 'pending',
      'initialized_at_progress': .52,
      'created_at': 100,
      'updated_at': 100,
    });

    final positions = await service.merge([
      ReadingAgentBookDelta(
        bookKey: 'book-md5',
        deviceId: 'device-b',
        generatedAt: 200,
        rows: {
          'tb_book_device_positions': [
            {
              'book_id': 99,
              'device_id': 'device-b',
              'cfi': 'remote-70',
              'progress': .70,
              'updated_at': 200,
            }
          ],
          'tb_book_reading_coverage': [
            {
              'book_id': 99,
              'safe_knowledge_boundary': .70,
              'artifact_coverage_start': .10,
              'artifact_coverage_end': .70,
              'setup_status': 'backfilled',
              'initialized_at_progress': .52,
              'created_at': 100,
              'updated_at': 200,
            }
          ],
        },
      ),
    ], database: db);

    expect(positions[1]!.cfi, 'local-52');
    expect(positions[1]!.progress, .52);
    final allPositions = await db.query('tb_book_device_positions');
    expect(allPositions, hasLength(2));
    final farthest = await db.rawQuery(
        'SELECT MAX(progress) AS value FROM tb_book_device_positions');
    expect(farthest.single['value'], .70);
    final coverage = (await db.query('tb_book_reading_coverage')).single;
    expect(coverage['safe_knowledge_boundary'], .70);
    expect(coverage['artifact_coverage_start'], .10);
    expect(coverage['setup_status'], 'backfilled');
  });

  test('finds only a navigable farthest position from another device',
      () async {
    final dao = ReadingAgentSyncDao(databaseProvider: () async => db);
    for (final row in [
      {
        'book_id': 1,
        'device_id': 'device-a',
        'cfi': 'local-20',
        'progress': .20,
        'updated_at': 100,
      },
      {
        'book_id': 1,
        'device_id': 'device-b',
        'cfi': 'remote-26',
        'progress': .26,
        'updated_at': 200,
      },
      {
        'book_id': 1,
        'device_id': 'device-c',
        'cfi': '',
        'progress': .30,
        'updated_at': 300,
      },
    ]) {
      await db.insert('tb_book_device_positions', row);
    }

    final remote = await dao.farthestOtherPosition(1, 'device-a');

    expect(remote?.deviceId, 'device-b');
    expect(remote?.cfi, 'remote-26');
    expect(remote?.progress, .26);
  });

  test('artifact keeps conservative spoiler boundary across equal conflicts',
      () async {
    Map<String, dynamic> artifact(double visible, String status) => {
          'id': 'artifact-1',
          'book_id': 1,
          'module_id': 'fiction.immersion',
          'artifact_kind': 'fiction.character',
          'payload_json': '{}',
          'epistemic_status': 'textFact',
          'status': status,
          'source_text_snapshot': '',
          'source_progress': .18,
          'visible_from_progress': visible,
          'ingested_at': 100,
          'ingestion_mode': 'backfill',
          'created_by': 'agent',
          'created_at': 100,
          'updated_at': 200,
        };
    await db.insert('tb_reading_artifacts', artifact(.18, 'active'));
    final service = ReadingAgentSyncService(deviceId: 'device-a');

    await service.merge([
      ReadingAgentBookDelta(
        bookKey: 'book-md5',
        deviceId: 'device-b',
        generatedAt: 200,
        rows: {
          'tb_reading_artifacts': [artifact(.25, 'retracted')]
        },
      ),
    ], database: db);

    final row = (await db.query('tb_reading_artifacts')).single;
    final merged = ReadingArtifact.fromDb(row);
    expect(merged.isVisibleAtProgress(.24), isFalse);
    expect(merged.isVisibleAtProgress(.25), isTrue);
    expect(merged.status, ReadingArtifactStatus.retracted);
  });

  test('user-pinned profile wins and latest active goal remains unique',
      () async {
    await db.insert('tb_book_reading_profiles', {
      'book_id': 1,
      'primary_module_id': 'fiction.immersion',
      'pinned': 1,
      'match_source': 'user',
      'created_at': 100,
      'updated_at': 100,
    });
    await db.insert('tb_reading_goals', {
      'id': 'old-goal',
      'book_id': 1,
      'title': '旧目标',
      'status': 'active',
      'created_at': 100,
      'updated_at': 100,
    });
    final service = ReadingAgentSyncService(deviceId: 'device-a');
    await service.merge([
      ReadingAgentBookDelta(
        bookKey: 'book-md5',
        deviceId: 'device-b',
        generatedAt: 200,
        rows: {
          'tb_book_reading_profiles': [
            {
              'book_id': 1,
              'primary_module_id': 'knowledge.argument',
              'pinned': 0,
              'match_source': 'metadata',
              'created_at': 100,
              'updated_at': 200,
            }
          ],
          'tb_reading_goals': [
            {
              'id': 'new-goal',
              'book_id': 1,
              'title': '新目标',
              'status': 'active',
              'created_at': 200,
              'updated_at': 200,
            }
          ],
        },
      ),
    ], database: db);

    final profile = (await db.query('tb_book_reading_profiles')).single;
    expect(profile['primary_module_id'], 'fiction.immersion');
    final active =
        await db.query('tb_reading_goals', where: "status = 'active'");
    expect(active.single['id'], 'new-goal');
  });

  test('newer tombstone prevents an older artifact from returning', () async {
    final service = ReadingAgentSyncService(deviceId: 'device-a');
    await service.merge([
      ReadingAgentBookDelta(
        bookKey: 'book-md5',
        deviceId: 'device-b',
        generatedAt: 300,
        rows: {
          'tb_reading_sync_tombstones': [
            {
              'entity_type': 'artifact',
              'entity_id': 'deleted-artifact',
              'book_id': 1,
              'device_id': 'device-b',
              'deleted_at': 300,
            }
          ],
          'tb_reading_artifacts': [
            {
              'id': 'deleted-artifact',
              'book_id': 1,
              'module_id': 'fiction.immersion',
              'artifact_kind': 'fiction.character',
              'payload_json': '{}',
              'epistemic_status': 'textFact',
              'source_text_snapshot': '',
              'source_progress': .18,
              'visible_from_progress': .18,
              'ingested_at': 100,
              'created_by': 'agent',
              'created_at': 100,
              'updated_at': 200,
            }
          ],
        },
      ),
    ], database: db);

    expect(await db.query('tb_reading_artifacts'), isEmpty);
  });
}
