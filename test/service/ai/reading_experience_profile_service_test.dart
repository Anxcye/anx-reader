import 'dart:io';

import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/dao/reading_agent.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/reading_closure_policy.dart';
import 'package:anx_reader/service/ai/reading_experience_profile_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late Database db;
  late ReadingAgentDao dao;
  late ReadingExperienceProfileService service;
  var now = 1000;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reading_profile_');
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
    dao = ReadingAgentDao(databaseProvider: () async => db);
    service = ReadingExperienceProfileService(dao: dao, clock: () => now);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  test('legacy enum name migrates to a pinned stable module id', () async {
    final profile = await service.loadOrCreate(
      bookId: 1,
      detectedModuleId: ReadingClosureIds.knowledgeArgument,
      legacyPreference: 'fictionImmersion',
    );

    expect(profile.primaryModuleId, ReadingClosureIds.fictionImmersion);
    expect(profile.pinned, isTrue);
    expect(profile.confidence, 1);
    expect(profile.matchSource, BookReadingProfileMatchSource.legacyPreference);
  });

  test('automatic profile is persisted and restored by a new service',
      () async {
    await service.loadOrCreate(
      bookId: 2,
      detectedModuleId: ReadingClosureIds.psychologyReflection,
      detectedFacets: const ['academic'],
      confidence: .82,
    );

    final restored = await ReadingExperienceProfileService(
      dao: dao,
      clock: () => now,
    ).loadOrCreate(
      bookId: 2,
      detectedModuleId: ReadingClosureIds.knowledgeArgument,
    );

    expect(restored.primaryModuleId, ReadingClosureIds.psychologyReflection);
    expect(restored.facets, ['academic']);
    expect(restored.confidence, .82);
    expect(restored.pinned, isFalse);
  });

  test('switching back to automatic removes the user pin', () async {
    await service.setPinned(
      bookId: 3,
      moduleId: ReadingClosureIds.fictionImmersion,
      facets: const ['historical'],
    );
    now += 1;
    final automatic = await service.setAutomatic(
      bookId: 3,
      detectedModuleId: ReadingClosureIds.knowledgeArgument,
      detectedFacets: const ['finance'],
      confidence: .7,
    );

    expect(automatic.pinned, isFalse);
    expect(automatic.primaryModuleId, ReadingClosureIds.knowledgeArgument);
    expect(automatic.matchSource, BookReadingProfileMatchSource.metadata);
    expect((await dao.bookReadingProfile(3))?.facets, ['finance']);
  });
}
