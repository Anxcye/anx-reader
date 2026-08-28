import 'dart:io';

import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/dao/reading_agent.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/fiction_reading_service.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late Database db;
  late ReadingAgentRepository repository;
  late FictionReadingService service;
  var now = 1000;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('fiction_reading_');
    db = await databaseFactoryFfi.openDatabase(p.join(tempDir.path, 'test.db'));
    for (final sql in [
      createReadingAgentSQL,
      createReadingClosureSQL,
      createReadingExperienceModulesSQL,
      createReadingCoverageSQL,
    ]) {
      for (final statement in sql
          .split(';')
          .map((value) => value.trim())
          .where((value) => value.isNotEmpty)) {
        await db.execute(statement);
      }
    }
    final dao = ReadingAgentDao(databaseProvider: () async => db);
    repository = ReadingAgentRepository(dao: dao, clock: () => now);
    service = FictionReadingService(repository: repository);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  Future<void> save({
    required String id,
    required String kind,
    required Map<String, dynamic> payload,
    required double progress,
    ReadingArtifactStatus status = ReadingArtifactStatus.active,
    ReadingArtifactEpistemicStatus epistemicStatus =
        ReadingArtifactEpistemicStatus.textFact,
  }) async {
    now += 1;
    await repository.saveSystemArtifact(ReadingArtifact(
      id: id,
      bookId: 1,
      moduleId: ReadingClosureIds.fictionImmersion,
      kind: kind,
      payload: payload,
      status: status,
      epistemicStatus: epistemicStatus,
      chapterHref: '$id.xhtml',
      sourceProgress: progress,
      visibleFromProgress: progress,
      ingestedAt: now,
      createdAt: now,
      updatedAt: now,
    ));
  }

  test('character recall matches aliases and enforces spoiler progress',
      () async {
    await save(
      id: 'early',
      kind: ReadingArtifactKinds.character,
      payload: const {
        'name': '福尔摩斯',
        'aliases': ['夏洛克'],
        'summary': '住在贝克街的侦探',
        'relationships': ['华生的朋友'],
      },
      progress: .3,
      epistemicStatus: ReadingArtifactEpistemicStatus.agentInference,
    );
    await save(
      id: 'future',
      kind: ReadingArtifactKinds.character,
      payload: const {'name': '莫里亚蒂', 'summary': '尚未登场'},
      progress: .6,
    );

    final recall = await service.recallCharacter(
      bookId: 1,
      query: '夏洛克',
      currentProgress: .4,
    );
    expect(recall?.name, '福尔摩斯');
    expect(recall?.relationships, ['华生的朋友']);
    expect(
      recall?.epistemicStatus,
      ReadingArtifactEpistemicStatus.agentInference,
    );
    expect(
      await service.recallCharacter(
        bookId: 1,
        query: '莫里亚蒂',
        currentProgress: .4,
      ),
      isNull,
    );
  });

  test('mystery ledger can hide resolved items', () async {
    await save(
      id: 'open',
      kind: ReadingArtifactKinds.mystery,
      payload: const {'question': '谁留下了信？'},
      progress: .2,
    );
    await save(
      id: 'resolved',
      kind: ReadingArtifactKinds.mystery,
      payload: const {'question': '门如何打开？'},
      progress: .25,
      status: ReadingArtifactStatus.resolved,
    );

    expect(
      await service.mysteryLedger(
        bookId: 1,
        currentProgress: .4,
        includeResolved: false,
      ),
      hasLength(1),
    );
  });

  test('resume context only projects artifacts visible at current progress',
      () async {
    await save(
      id: 'scene',
      kind: ReadingArtifactKinds.resumeContext,
      payload: const {'summary': '上次读到车站告别'},
      progress: .35,
    );
    await save(
      id: 'character',
      kind: ReadingArtifactKinds.character,
      payload: const {'name': '阿青'},
      progress: .3,
    );
    await save(
      id: 'mystery',
      kind: ReadingArtifactKinds.mystery,
      payload: const {'question': '信是谁写的？'},
      progress: .32,
    );
    await save(
      id: 'future-character',
      kind: ReadingArtifactKinds.character,
      payload: const {'name': '未来人物'},
      progress: .8,
    );

    final context = await service.resumeContext(
      bookId: 1,
      currentProgress: .4,
    );
    expect(context.lastScene, '上次读到车站告别');
    expect(context.activeCharacters, contains('阿青'));
    expect(context.activeCharacters, isNot(contains('未来人物')));
    expect(context.openMysteries.single.payload['question'], '信是谁写的？');
  });
}
