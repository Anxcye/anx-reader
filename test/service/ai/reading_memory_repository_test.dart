import 'dart:io';

import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/dao/reading_coach.dart';
import 'package:anx_reader/dao/reading_memory.dart';
import 'package:anx_reader/dao/reading_note.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/service/ai/reading_memory_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late Database database;
  late ReadingMemoryDao memoryDao;
  late ReadingMemoryRepository repository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anx_reading_memory_');
    database = await databaseFactoryFfi.openDatabase(
      p.join(tempDir.path, 'memory.db'),
    );
    await database.execute(createReadingDifficultiesSQL);
    await database.execute('''
      CREATE TABLE tb_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT, book_id INTEGER,
        content TEXT, cfi TEXT, chapter TEXT, type TEXT, color TEXT,
        reader_note TEXT, create_time TEXT, update_time TEXT
      )
    ''');
    for (final statement in createReadingMemorySQL
        .split(';')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)) {
      await database.execute(statement);
    }
    for (final statement in createReadingNotesWorkspaceSQL
        .split(';')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)) {
      await database.execute(statement);
    }
    Future<Database> provider() async => database;
    memoryDao = ReadingMemoryDao(databaseProvider: provider);
    repository = ReadingMemoryRepository(
      dao: memoryDao,
      coachDao: ReadingCoachDao(databaseProvider: provider),
      noteDao: BookNoteDao(databaseProvider: provider),
      formalNoteDao: ReadingNoteDao(databaseProvider: provider),
    );
  });

  tearDown(() async {
    await database.close();
    await tempDir.delete(recursive: true);
  });

  test('source collection is book-scoped, truncated, deduplicated and capped',
      () async {
    final longText = List.filled(300, '字').join();
    for (var index = 0; index < 82; index++) {
      await database.insert('tb_reading_difficulties', {
        'id': 'difficulty-$index',
        'book_id': 7,
        'cfi': 'epubcfi(/6/$index)',
        'selected_text': index == 0 ? longText : '难点 $index',
        'difficulty_type': 'later',
        'status': 'unresolved',
        'created_at': index,
        'updated_at': index,
      });
    }
    await database.insert('tb_reading_difficulties', {
      'id': 'other-book',
      'book_id': 8,
      'cfi': 'epubcfi(/6/2)',
      'selected_text': '不应出现',
      'difficulty_type': 'later',
      'status': 'unresolved',
      'created_at': 1,
      'updated_at': 1,
    });

    final sources = await repository.collectSources(7);

    expect(sources, hasLength(80));
    expect(sources.every((source) => source.bookId == 7), isTrue);
    expect(sources.map((source) => source.contentHash).toSet(), hasLength(80));
    expect(sources.every((source) => source.text.length <= 240), isTrue);
  });

  test('identical source text and CFI remain isolated between books', () async {
    for (final bookId in [7, 8]) {
      await database.insert('tb_reading_difficulties', {
        'id': 'difficulty-$bookId',
        'book_id': bookId,
        'cfi': 'epubcfi(/6/2)',
        'selected_text': '相同内容',
        'difficulty_type': 'later',
        'status': 'unresolved',
        'created_at': 1,
        'updated_at': 1,
      });
    }

    final first = (await repository.collectSources(7)).single;
    final second = (await repository.collectSources(8)).single;

    expect(first.id, isNot(second.id));
    expect(await repository.sources(7), hasLength(1));
    expect(await repository.sources(8), hasLength(1));
  });

  test('formal reading notes are collected as independent memory sources',
      () async {
    await database.insert('tb_reading_notes', {
      'id': 'note-1',
      'book_id': 7,
      'title': '标题',
      'status': 'active',
      'capture_kind': 'question',
      'is_favorite': 0,
      'created_at': 1,
      'updated_at': 1,
    });
    await database.insert('tb_reading_note_blocks', {
      'id': 'block-1',
      'note_id': 'note-1',
      'block_type': 'text',
      'content': '正式笔记中的问题',
      'sort_order': 1,
      'origin': 'user',
      'created_at': 1,
      'updated_at': 1,
    });

    final source = (await repository.collectSources(7)).single;

    expect(source.type, ReadingMemorySourceType.readingNote);
    expect(source.sourceRef, 'note-1');
    expect(source.text, '正式笔记中的问题');

    await database
        .delete('tb_reading_notes', where: 'id = ?', whereArgs: ['note-1']);
    final stored = (await repository.sources(7)).single;
    expect(stored.text, '正式笔记中的问题');
    expect(stored.isAvailable, isFalse);
  });

  test('suggested topic sources are excluded from incremental collection',
      () async {
    await database.insert('tb_reading_difficulties', {
      'id': 'difficulty-1',
      'book_id': 7,
      'cfi': 'epubcfi(/6/2)',
      'selected_text': '需要整理的难点',
      'difficulty_type': 'later',
      'status': 'unresolved',
      'created_at': 1,
      'updated_at': 1,
    });
    final source = (await repository.collectSources(7)).single;
    await repository.saveTopics([
      ReadingMemoryTopic(
        id: 'topic-1',
        bookId: 7,
        title: '主题',
        summary: '摘要',
        status: ReadingMemoryItemStatus.suggested,
        batchId: 'batch-1',
        sourceIds: [source.id],
        createdAt: 1,
        updatedAt: 1,
      ),
    ]);

    expect(await repository.collectSources(7), isEmpty);
    expect(await repository.collectSources(7, includeUsed: true), hasLength(1));
  });

  test('deleted original source keeps its snapshot but is not navigable',
      () async {
    await database.insert('tb_reading_difficulties', {
      'id': 'difficulty-1',
      'book_id': 7,
      'cfi': 'epubcfi(/6/2)',
      'selected_text': '即使删除原记录也应保留的快照',
      'difficulty_type': 'later',
      'status': 'unresolved',
      'created_at': 1,
      'updated_at': 1,
    });
    final source = (await repository.collectSources(7)).single;
    expect((await repository.sources(7)).single.isAvailable, isTrue);

    await database.delete('tb_reading_difficulties',
        where: 'id = ?', whereArgs: ['difficulty-1']);
    final deleted = (await repository.sources(7)).single;

    expect(deleted.isAvailable, isFalse);
    expect(deleted.text, source.text);
    expect(deleted.cfi, source.cfi);
  });

  test('review and undo restore schedule and counters transactionally',
      () async {
    final card = ReadingKnowledgeCard(
      id: 'card-1',
      bookId: 7,
      topicId: 'topic-1',
      question: '问题',
      answer: '答案',
      status: ReadingMemoryItemStatus.active,
      nextReviewAt: 100,
      createdAt: 1,
      updatedAt: 1,
    );
    await repository.saveCards([card]);

    await repository.review(card, ReadingReviewRating.mastered, now: 1000);
    var stored = (await repository.cards(7)).single;
    expect(stored.reviewStage, 3);
    expect(stored.masteredCount, 1);
    expect(await repository.reviews(7), hasLength(1));

    await repository.undoLatest(7);
    stored = (await repository.cards(7)).single;
    expect(stored.reviewStage, 1);
    expect(stored.nextReviewAt, 100);
    expect(stored.masteredCount, 0);
    expect(await repository.reviews(7), isEmpty);
  });

  test('permanent cleanup removes only the requested book memory', () async {
    for (final bookId in [7, 8]) {
      final source = ReadingMemorySource(
        id: 'source-$bookId',
        bookId: bookId,
        type: ReadingMemorySourceType.difficulty,
        text: 'source',
        contentHash: 'hash-$bookId',
        createdAt: 1,
      );
      await memoryDao.saveSources([source]);
      await repository.saveTopics([
        ReadingMemoryTopic(
          id: 'topic-$bookId',
          bookId: bookId,
          title: 'topic',
          summary: 'summary',
          status: ReadingMemoryItemStatus.kept,
          batchId: 'batch',
          sourceIds: [source.id],
          createdAt: 1,
          updatedAt: 1,
        ),
      ]);
      await repository.saveCards([
        ReadingKnowledgeCard(
          id: 'card-$bookId',
          bookId: bookId,
          topicId: 'topic-$bookId',
          question: 'question',
          answer: 'answer',
          status: ReadingMemoryItemStatus.active,
          sourceIds: [source.id],
          nextReviewAt: 1,
          createdAt: 1,
          updatedAt: 1,
        ),
      ]);
    }
    await repository.review(
      (await repository.cards(7)).single,
      ReadingReviewRating.remembered,
      now: 10,
    );

    await repository.deleteBookMemory(7);

    expect(await repository.sources(7), isEmpty);
    expect(await repository.topics(7), isEmpty);
    expect(await repository.cards(7), isEmpty);
    expect(await repository.reviews(7), isEmpty);
    expect(await repository.sources(8), hasLength(1));
    expect(await repository.topics(8), hasLength(1));
    expect(await repository.cards(8), hasLength(1));
  });
}
