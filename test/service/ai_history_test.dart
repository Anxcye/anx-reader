import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/ai_session.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/service/ai/ai_history.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:path/path.dart' as p;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late Database database;
  late AiSessionDao dao;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    Prefs().prefs = await SharedPreferences.getInstance();
    tempDir = await Directory.systemTemp.createTemp('anx_ai_history_test_');
    database = await databaseFactoryFfi.openDatabase(
      p.join(tempDir.path, 'history.db'),
    );
    await database.execute(createAiSessionsSQL);
    dao = AiSessionDao(databaseProvider: () async => database);
  });

  tearDown(() async {
    await database.close();
    if (tempDir.existsSync()) {
      await tempDir.delete(recursive: true);
    }
  });

  AiChatHistoryEntry entry({
    required String id,
    required int updatedAt,
    String? title,
  }) {
    return AiChatHistoryEntry(
      id: id,
      serviceId: 'openai',
      model: 'gpt-test',
      createdAt: 100,
      updatedAt: updatedAt,
      messages: [ChatMessage.humanText('Hello $id')],
      completed: true,
      title: title,
      bookId: 7,
      bookTitle: 'Book',
      chapterTitle: 'Chapter',
      chapterHref: 'chapter.xhtml',
      readingMode: 'epub',
      analysisDepth: 'deep',
      frameworks: const ['firstPrinciples', 'systemsThinking'],
      outputTemplate: 'argumentAnalysis',
      readingGoal: 'Test the argument',
      analysisResult: const {
        'summary': 'Structured result',
        'generatedAt': 123,
      },
      contextSnapshot: const {'selection': 'text'},
      agentTraces: const [
        {'tool': 'search'}
      ],
      citations: const [
        {'url': 'https://example.com'}
      ],
    );
  }

  test('SQLite round-trip preserves metadata and applies history limit',
      () async {
    final noLegacyFile = File(p.join(tempDir.path, 'none.json'));
    await AiHistoryStore.upsertEntry(
      entry(id: 'older', updatedAt: 200),
      sessionDao: dao,
      legacyFile: noLegacyFile,
      maxCount: 1,
    );
    await AiHistoryStore.upsertEntry(
      entry(id: 'newer', updatedAt: 300, title: 'Saved title'),
      sessionDao: dao,
      legacyFile: noLegacyFile,
      maxCount: 1,
    );

    final history = await AiHistoryStore.readHistory(
      sessionDao: dao,
      legacyFile: noLegacyFile,
    );

    expect(history, hasLength(1));
    final restored = history.single;
    expect(restored.id, 'newer');
    expect(restored.title, 'Saved title');
    expect(restored.bookId, 7);
    expect(restored.contextSnapshot, {'selection': 'text'});
    expect(restored.analysisDepth, 'deep');
    expect(restored.frameworks, ['firstPrinciples', 'systemsThinking']);
    expect(restored.outputTemplate, 'argumentAnalysis');
    expect(restored.readingGoal, 'Test the argument');
    expect(restored.analysisResult?['summary'], 'Structured result');
    expect(restored.agentTraces, [
      {'tool': 'search'}
    ]);
    expect(restored.citations, [
      {'url': 'https://example.com'}
    ]);
    expect(restored.messages.single.contentAsString, 'Hello newer');
  });

  test('first read imports legacy JSON without replacing existing DB rows',
      () async {
    await AiHistoryStore.upsertEntry(
      entry(id: 'same', updatedAt: 500, title: 'Database title'),
      sessionDao: dao,
      legacyFile: File(p.join(tempDir.path, 'no_legacy.json')),
      maxCount: 10,
    );
    final legacyFile = File(p.join(tempDir.path, 'ai_history.json'));
    await legacyFile.writeAsString(json.encode([
      entry(id: 'same', updatedAt: 100, title: 'Legacy title').toJson(),
      entry(id: 'imported', updatedAt: 200).toJson(),
    ]));

    final history = await AiHistoryStore.readHistory(
      sessionDao: dao,
      legacyFile: legacyFile,
    );

    expect(history.map((item) => item.id), containsAll(['same', 'imported']));
    expect(history.firstWhere((item) => item.id == 'same').title,
        'Database title');
    expect(await legacyFile.exists(), isFalse);
    expect(await File('${legacyFile.path}.backup').exists(), isTrue);
  });

  test('damaged legacy JSON neither changes DB nor gets deleted', () async {
    await AiHistoryStore.upsertEntry(
      entry(id: 'database', updatedAt: 500),
      sessionDao: dao,
      legacyFile: File(p.join(tempDir.path, 'no_legacy.json')),
      maxCount: 10,
    );
    final damagedFile = File(p.join(tempDir.path, 'damaged_history.json'));
    await damagedFile.writeAsString('{not valid json');

    final history = await AiHistoryStore.readHistory(
      sessionDao: dao,
      legacyFile: damagedFile,
    );

    expect(history.map((item) => item.id), ['database']);
    expect(await damagedFile.exists(), isTrue);
    expect(await File('${damagedFile.path}.backup').exists(), isFalse);
  });

  test('old JSON remains compatible and metadata defaults are empty', () {
    final restored = AiChatHistoryEntry.fromJson({
      'id': 'legacy',
      'serviceId': 'anthropic',
      'model': 'legacy-model',
      'createdAt': 1,
      'updatedAt': 2,
      'completed': false,
      'messages': [ChatMessage.humanText('Legacy').toMap()],
    });

    expect(restored.serviceId, 'anthropic');
    expect(restored.title, isNull);
    expect(restored.contextSnapshot, isNull);
    expect(restored.agentTraces, isEmpty);
    expect(restored.citations, isEmpty);
    expect(restored.frameworks, isEmpty);
    expect(restored.analysisResult, isNull);
  });
}
