import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/dao/reading_note.dart';
import 'package:anx_reader/dao/reading_note_ai.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/reading_note_ai.dart';
import 'package:anx_reader/dao/reading_memory.dart';
import 'package:anx_reader/service/reading_note/reading_note_ai_batch_repository.dart';
import 'package:anx_reader/service/reading_note/reading_note_ai_organizer_service.dart';
import 'package:anx_reader/service/reading_note/reading_note_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late Database database;
  late ReadingNoteDao noteDao;
  late BookNoteDao annotationDao;
  late ReadingNoteRepository repository;
  late ReadingNoteAiBatchRepository aiRepository;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('anx_reading_notes_');
    database = await databaseFactoryFfi.openDatabase(
      p.join(tempDir.path, 'notes.db'),
    );
    await database.execute('''
      CREATE TABLE tb_books (
        id INTEGER PRIMARY KEY, title TEXT, cover_path TEXT, file_path TEXT,
        last_read_position TEXT, reading_percentage REAL, author TEXT,
        is_deleted INTEGER, description TEXT, rating REAL, group_id INTEGER,
        file_md5 TEXT, create_time TEXT, update_time TEXT
      )
    ''');
    await database.execute('''
      CREATE TABLE tb_notes (
        id INTEGER PRIMARY KEY AUTOINCREMENT, book_id INTEGER,
        content TEXT, cfi TEXT, chapter TEXT, type TEXT, color TEXT,
        reader_note TEXT, create_time TEXT, update_time TEXT
      )
    ''');
    for (final statement in createReadingNotesWorkspaceSQL
        .split(';')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)) {
      await database.execute(statement);
    }
    for (final statement in createReadingMemorySQL
        .split(';')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)) {
      await database.execute(statement);
    }
    for (final statement in createReadingNoteAiOrganizerSQL
        .split(';')
        .map((value) => value.trim())
        .where((value) => value.isNotEmpty)) {
      await database.execute(statement);
    }
    await database.insert('tb_books', {
      'id': 7,
      'title': '测试书',
      'cover_path': '',
      'file_path': 'book.epub',
      'last_read_position': '',
      'reading_percentage': 0.2,
      'author': '作者',
      'is_deleted': 0,
      'rating': 0.0,
      'group_id': 0,
      'create_time': DateTime(2026).toIso8601String(),
      'update_time': DateTime(2026).toIso8601String(),
    });
    Future<Database> provider() async => database;
    noteDao = ReadingNoteDao(databaseProvider: provider);
    annotationDao = BookNoteDao(databaseProvider: provider);
    repository = ReadingNoteRepository(
      dao: noteDao,
      annotationDao: annotationDao,
      books: BookDao(databaseProvider: provider),
    );
    aiRepository = ReadingNoteAiBatchRepository(
      aiDao: ReadingNoteAiDao(databaseProvider: provider),
      noteDao: noteDao,
      memoryDao: ReadingMemoryDao(databaseProvider: provider),
      notes: repository,
    );
  });

  tearDown(() async {
    await database.close();
    await tempDir.delete(recursive: true);
  });

  Future<BookNote> createAnnotation() async {
    final annotation = BookNote(
      bookId: 7,
      content: '原文引用',
      cfi: 'epubcfi(/6/2)',
      chapter: '第一章',
      type: 'highlight',
      color: 'fff59d',
      createTime: DateTime(2026),
      updateTime: DateTime(2026),
    );
    annotation.id = await annotationDao.save(annotation);
    return annotation;
  }

  test('legacy annotation is lazily mapped once and suppressed from list',
      () async {
    final annotation = await createAnnotation();
    final legacy = (await repository.list(const ReadingNoteQuery())).single;
    expect(legacy.isLegacy, isTrue);

    final mapped = await repository.mapLegacy(annotation);
    final mappedAgain = await repository.mapLegacy(annotation);
    final items = await repository.list(const ReadingNoteQuery());

    expect(mappedAgain.note.id, mapped.note.id);
    expect(items, hasLength(1));
    expect(items.single.isLegacy, isFalse);
    expect(items.single.quote, '原文引用');
  });

  test('autosave mirrors legacy note without revision; checkpoint records one',
      () async {
    final document = await repository.mapLegacy(await createAnnotation());

    final autosaved = await repository.save(
      currentDocument: document,
      title: '问题',
      body: '我的想法',
      status: ReadingNoteStatus.active,
      favorite: false,
      tagNames: const ['认知'],
    );
    expect(await noteDao.revisions(document.note.id), isEmpty);
    expect((await annotationDao.selectBookNoteById(1)).readerNote, '我的想法');

    await repository.save(
      currentDocument: autosaved,
      title: '问题',
      body: '修订后的想法',
      status: ReadingNoteStatus.active,
      favorite: true,
      tagNames: const ['认知'],
      recordRevision: true,
    );
    final revisions = await noteDao.revisions(document.note.id);
    expect(revisions, hasLength(1));
    expect(revisions.single.body, '修订后的想法');
  });

  test('permanent formal-note deletion leaves original annotation intact',
      () async {
    final annotation = await createAnnotation();
    final document = await repository.capture(
      annotation: annotation,
      kind: ReadingNoteCaptureKind.question,
    );

    await repository.deletePermanently(document.note.id);

    expect(await noteDao.note(document.note.id), isNull);
    expect((await annotationDao.selectBookNoteById(annotation.id!)).content,
        '原文引用');
  });

  test('deleted annotation marks formal source unavailable but keeps snapshot',
      () async {
    final annotation = await createAnnotation();
    final document = await repository.mapLegacy(annotation);
    await annotationDao.deleteBookNoteById(annotation.id!);

    final loaded = await repository.document(document.note);

    expect(loaded.sources.single.isAvailable, isFalse);
    expect(loaded.sources.single.textSnapshot, '原文引用');
  });

  test('AI adoption lazily maps annotation and preserves user-owned fields',
      () async {
    await createAnnotation();
    final book = (await repository.books()).single;
    final legacy = (await repository.list(
      const ReadingNoteQuery(bookId: 7),
    ))
        .single;
    final prepared = await aiRepository.prepare(
      book: book,
      scope: ReadingNoteAiScope.selected,
      items: [legacy],
    );
    expect(await noteDao.mappedAnnotationId(1), isNull);
    await aiRepository.saveGenerated(
      batch: prepared.batch,
      inputs: prepared.inputs,
      parsed: const [
        ReadingNoteAiParsedSuggestion(
          sourceId: 'annotation:1',
          title: '建议标题',
          body: 'AI 梳理内容',
          tags: ['重点'],
          existingTopicIds: [],
          newTopics: [
            {'title': '论证', 'summary': '论证结构'}
          ],
        ),
      ],
      providerId: 'fallback-provider',
      model: 'fallback-model',
      usedFallback: true,
    );
    final suggestion =
        (await aiRepository.suggestions(prepared.batch.id)).single;

    final adopted = await aiRepository.apply(
      suggestion,
      providerId: 'fallback-provider',
      model: 'fallback-model',
      usedFallback: true,
    );

    expect(adopted, isNotNull);
    expect(adopted!.quote, '原文引用');
    expect(adopted.body, isEmpty);
    expect(adopted.note.captureKind, ReadingNoteCaptureKind.highlight);
    expect(adopted.note.status, ReadingNoteStatus.active);
    expect(adopted.tags.map((tag) => tag.name), contains('重点'));
    final aiBlock = adopted.blocks
        .singleWhere((block) => block.type == ReadingNoteBlockType.ai);
    expect(aiBlock.content, 'AI 梳理内容');
    expect(aiBlock.metadata['providerId'], 'fallback-provider');
    expect(aiBlock.metadata['model'], 'fallback-model');
    expect(aiBlock.metadata['usedFallback'], isTrue);
    final topics = await aiRepository.keptTopics(7);
    expect(topics, isEmpty);
    final suggestedTopics = await ReadingMemoryDao(
      databaseProvider: () async => database,
    ).topics(7);
    expect(suggestedTopics.single.status, ReadingMemoryItemStatus.suggested);
    expect(
      adopted.sources
          .where((source) => source.type == ReadingNoteSourceType.memoryTopic),
      isEmpty,
    );
  });

  test('AI adoption refuses changed content and undo restores safe snapshot',
      () async {
    final document = await repository.mapLegacy(await createAnnotation());
    final book = (await repository.books()).single;
    final item = (await repository.list(
      const ReadingNoteQuery(bookId: 7),
    ))
        .single;
    final prepared = await aiRepository.prepare(
      book: book,
      scope: ReadingNoteAiScope.selected,
      items: [item],
    );
    await aiRepository.saveGenerated(
      batch: prepared.batch,
      inputs: prepared.inputs,
      parsed: [
        ReadingNoteAiParsedSuggestion(
          sourceId: 'readingNote:${document.note.id}',
          title: 'AI 标题',
          body: 'AI 内容',
          tags: const [],
          existingTopicIds: const [],
          newTopics: const [],
        ),
      ],
      providerId: 'provider',
      model: 'model',
      usedFallback: false,
    );
    var suggestion = (await aiRepository.suggestions(prepared.batch.id)).single;
    final edited = await repository.save(
      currentDocument: document,
      title: '用户编辑',
      body: '用户正文',
      status: document.note.status,
      favorite: false,
      tagNames: const [],
    );
    await expectLater(
      aiRepository.apply(suggestion,
          providerId: 'provider', model: 'model', usedFallback: false),
      throwsStateError,
    );

    final freshPrepared = await aiRepository.prepare(
      book: book,
      scope: ReadingNoteAiScope.selected,
      items: [ReadingNoteListItem(document: edited, book: book)],
    );
    await aiRepository.saveGenerated(
      batch: freshPrepared.batch,
      inputs: freshPrepared.inputs,
      parsed: [
        ReadingNoteAiParsedSuggestion(
          sourceId: 'readingNote:${document.note.id}',
          title: 'AI 标题',
          body: 'AI 内容',
          tags: const [],
          existingTopicIds: const [],
          newTopics: const [],
        ),
      ],
      providerId: 'provider',
      model: 'model',
      usedFallback: false,
    );
    suggestion =
        (await aiRepository.suggestions(freshPrepared.batch.id)).single;
    await aiRepository.apply(suggestion,
        providerId: 'provider', model: 'model', usedFallback: false);
    suggestion =
        (await aiRepository.suggestions(freshPrepared.batch.id)).single;
    await aiRepository.undo(suggestion);

    final restored = await repository.document(
      (await noteDao.note(document.note.id))!,
    );
    expect(restored.note.title, '用户编辑');
    expect(restored.body, '用户正文');
    expect(restored.blocks.where((b) => b.type == ReadingNoteBlockType.ai),
        isEmpty);
  });
}
