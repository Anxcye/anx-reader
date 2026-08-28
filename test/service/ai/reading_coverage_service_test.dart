import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/dao/reading_agent.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:anx_reader/service/ai/reading_coverage_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  late Directory tempDir;
  late Database db;
  late ReadingCoverageService service;
  late ReadingAgentRepository repository;
  var now = 1000;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
    tempDir = await Directory.systemTemp.createTemp('reading_coverage_');
    db = await databaseFactoryFfi.openDatabase(p.join(tempDir.path, 'test.db'));
    await DBHelper().onUpgradeDatabase(db, 15, currentDbVersion);
    repository = ReadingAgentRepository(
      dao: ReadingAgentDao(databaseProvider: () async => db),
      clock: () => now,
    );
    service = ReadingCoverageService(repository: repository, clock: () => now);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('first fiction use at 52 percent stays pending and restores', () async {
    final coverage = await service.loadOrInitialize(
      bookId: 1,
      currentPosition: .52,
      supportsArtifacts: true,
    );
    expect(coverage.setupStatus, ReadingCoverageSetupStatus.pending);
    expect(coverage.safeKnowledgeBoundary, .52);
    expect(coverage.artifactCoverageStart, .52);
    expect(coverage.artifactCoverageEnd, .52);

    now += 100;
    final restored = await service.loadOrInitialize(
      bookId: 1,
      currentPosition: .7,
      supportsArtifacts: true,
    );
    expect(restored.initializedAtProgress, .52);
    expect(restored.setupStatus, ReadingCoverageSetupStatus.pending);
  });

  test('from here and backfill preserve independent boundaries', () async {
    final initial = await service.loadOrInitialize(
      bookId: 1,
      currentPosition: .52,
      supportsArtifacts: true,
    );
    final fromHere = await service.startFromHere(initial);
    expect(fromHere.setupStatus, ReadingCoverageSetupStatus.fromHere);
    expect(fromHere.artifactCoverageStart, .52);

    final backfilled =
        await service.markBackfilled(fromHere, throughProgress: .52);
    expect(backfilled.setupStatus, ReadingCoverageSetupStatus.backfilled);
    expect(backfilled.artifactCoverageStart, 0);
    expect(backfilled.artifactCoverageEnd, .52);
  });

  test('live artifacts expand actual coverage while setup stays passive',
      () async {
    final initial = await service.loadOrInitialize(
      bookId: 1,
      currentPosition: .52,
      supportsArtifacts: true,
    );
    await repository.saveSystemArtifact(ReadingArtifact(
      id: 'live-scene',
      bookId: 1,
      moduleId: 'fiction.immersion',
      kind: ReadingArtifactKinds.scene,
      payload: const {'summary': '当前场景'},
      chapterHref: 'chapter.xhtml',
      sourceProgress: .61,
      visibleFromProgress: .61,
      ingestedAt: now,
      createdAt: now,
      updatedAt: now,
    ));

    final restored = await service.loadOrInitialize(
      bookId: 1,
      currentPosition: .61,
      supportsArtifacts: true,
    );
    expect(initial.setupStatus, ReadingCoverageSetupStatus.pending);
    expect(restored.setupStatus, ReadingCoverageSetupStatus.pending);
    expect(restored.artifactCoverageStart, .52);
    expect(restored.artifactCoverageEnd, .61);
  });
}
