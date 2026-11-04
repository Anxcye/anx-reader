import 'dart:io';

import 'package:anx_reader/dao/database.dart';
import 'package:anx_reader/dao/reading_agent.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/service/ai/reading_agent_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late Directory tempDir;
  late Database db;
  late ReadingAgentDao dao;
  late ReadingAgentRepository repository;
  var now = 1000000;

  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
    sqfliteFfiInit();
  });

  setUp(() async {
    tempDir = await Directory.systemTemp.createTemp('reading_agent_repo_');
    db = await databaseFactoryFfi.openDatabase(p.join(tempDir.path, 'test.db'));
    for (final sql in [
      createNoteSQL,
      createReadingGuidesSQL,
      createReadingQuizzesSQL,
      createReadingDifficultiesSQL,
      createReadingMemorySQL,
      createReadingNotesWorkspaceSQL,
      createReadingNoteAiOrganizerSQL,
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
    await db.execute('ALTER TABLE tb_notes ADD COLUMN reader_note TEXT');
    dao = ReadingAgentDao(databaseProvider: () async => db);
    repository = ReadingAgentRepository(dao: dao, clock: () => now);
  });

  tearDown(() async {
    await db.close();
    await tempDir.delete(recursive: true);
  });

  ReadingGoal goal(String id, {int bookId = 1}) => ReadingGoal(
        id: id,
        bookId: bookId,
        title: 'Understand chapter',
        criteria: const [
          {'label': 'Explain the argument', 'completed': false},
        ],
        createdAt: now,
        updatedAt: now,
      );

  ReadingChapterCheckpoint checkpoint() => ReadingChapterCheckpoint(
      id: 'checkpoint',
      bookId: 1,
      chapterHref: 'one.xhtml',
      chapterTitle: 'One',
      progress: .4,
      createdAt: now,
      updatedAt: now);

  test('chapter closure persists and undoes all records and source anchors',
      () async {
    final pending = checkpoint();
    await repository.upsertCheckpoint(pending);
    final mutation = await repository.finishChapterCheckpoint(
        checkpoint: pending.copyWith(reflection: 'My reflection'),
        mastery: MasteryState(
            id: 'mastery',
            bookId: 1,
            chapterHref: 'one.xhtml',
            topic: 'One',
            level: MasteryLevel.familiar,
            updatedAt: now),
        card: KnowledgeCard(
            id: 'card',
            bookId: 1,
            chapterHref: 'one.xhtml',
            front: 'Recall',
            back: 'My reflection',
            createdAt: now,
            updatedAt: now),
        memory: ReadingMemoryDocument(
            id: 'memory',
            bookId: 1,
            title: 'Reflection',
            markdown: 'My reflection',
            sourceRefs: ['checkpoint:checkpoint'],
            createdAt: now,
            updatedAt: now),
        sessionId: 's1');
    expect(mutation.value.status, ReadingCheckpointStatus.completed);
    expect((await db.query('tb_reading_checkpoints')).single['reflection'],
        'My reflection');
    expect(await repository.masteryStates(1), hasLength(1));
    expect(await repository.knowledgeCards(1), hasLength(1));
    expect((await repository.memoryDocuments(1)).single.sourceRefs,
        ['checkpoint:checkpoint']);
    final anchors = await repository.artifacts(1);
    expect(anchors, hasLength(3));
    for (final anchor in anchors) {
      expect(anchor.sourceStartCfi, isNull);
      expect(anchor.sourceProgress, .4);
      expect(anchor.visibleFromProgress, .4);
      expect(anchor.payload['checkpointId'], pending.id);
    }
    expect(await repository.undo(mutation.action.id), UndoResult.undone);
    expect((await repository.pendingCheckpoints(1)).single.reflection, isEmpty);
    expect(await repository.masteryStates(1), isEmpty);
    expect(await repository.knowledgeCards(1), isEmpty);
    expect(await repository.memoryDocuments(1), isEmpty);
    expect(await repository.artifacts(1), isEmpty);
    expect(await repository.undo(mutation.action.id), UndoResult.alreadyUndone);
  });

  test('chapter closure rejects stale boundaries and rolls back ID conflicts',
      () async {
    final pending = checkpoint();
    await repository.upsertCheckpoint(pending);
    await expectLater(
        repository.finishChapterCheckpoint(
            checkpoint: pending.copyWith(progress: .2), sessionId: 's1'),
        throwsStateError);
    await repository.saveKnowledgeCard(KnowledgeCard(
        id: 'foreign',
        bookId: 2,
        front: 'Other book',
        back: 'Private',
        createdAt: now,
        updatedAt: now));
    await expectLater(
        repository.finishChapterCheckpoint(
            checkpoint: pending.copyWith(reflection: 'Must roll back'),
            card: KnowledgeCard(
                id: 'foreign',
                bookId: 1,
                chapterHref: pending.chapterHref,
                front: 'Recall',
                back: 'Answer',
                createdAt: now,
                updatedAt: now),
            sessionId: 's1'),
        throwsStateError);
    expect((await repository.pendingCheckpoints(1)).single.reflection, isEmpty);
    expect((await repository.knowledgeCards(2)).single.back, 'Private');
    expect(await repository.artifacts(1), isEmpty);
    expect(await db.query('tb_agent_actions'), isEmpty);
  });

  test('chapter closure undo conflict never partially rolls back records',
      () async {
    final pending = checkpoint();
    await repository.upsertCheckpoint(pending);
    final mutation = await repository.finishChapterCheckpoint(
        checkpoint: pending,
        card: KnowledgeCard(
            id: 'card',
            bookId: 1,
            chapterHref: pending.chapterHref,
            front: 'Recall',
            back: 'Original',
            createdAt: now,
            updatedAt: now),
        sessionId: 's1');
    await db.update('tb_knowledge_cards', {'back': 'User correction'},
        where: 'id = ?', whereArgs: ['card']);
    expect(await repository.undo(mutation.action.id), UndoResult.conflict);
    expect(await repository.pendingCheckpoints(1), isEmpty);
    expect((await repository.knowledgeCards(1)).single.back, 'User correction');
    expect(await repository.artifacts(1), hasLength(2));
  });

  test('knowledge-card review has conflict-safe and idempotent undo', () async {
    final card = KnowledgeCard(
        id: 'card',
        bookId: 1,
        front: 'Question',
        back: 'Answer',
        dueAt: now,
        createdAt: now,
        updatedAt: now);
    await repository.saveKnowledgeCard(card);
    final reviewed = card.copyWith(
        repetitions: 1, intervalDays: 2, dueAt: now + 2000, updatedAt: now + 1);
    final mutation =
        await repository.reviewKnowledgeCard(reviewed, sessionId: 's1');
    expect((await repository.knowledgeCards(1)).single.repetitions, 1);
    expect(await repository.undo(mutation.action.id), UndoResult.undone);
    expect((await repository.knowledgeCards(1)).single.repetitions, 0);
    expect(await repository.undo(mutation.action.id), UndoResult.alreadyUndone);
    final second =
        await repository.reviewKnowledgeCard(reviewed, sessionId: 's1');
    await db.update('tb_knowledge_cards', {'back': 'User correction'},
        where: 'id = ?', whereArgs: ['card']);
    expect(await repository.undo(second.action.id), UndoResult.conflict);
  });

  test('pending question and exact source anchor persist and undo atomically',
      () async {
    final question = ReadingDifficulty(
        id: 'question',
        bookId: 1,
        cfi: 'epubcfi(/6/2)',
        text: 'Why?',
        createdAt: now,
        updatedAt: now);
    final mutation = await repository.saveDifficulty(question,
        sessionId: 's1', sourceProgress: .4, visibleFromProgress: .4);
    final anchor = (await repository.artifacts(1)).single;
    expect(anchor.kind, ReadingArtifactKinds.sourceAnchor);
    expect(
        anchor.payload, {'sourceKind': 'difficulty', 'sourceId': 'question'});
    expect(anchor.sourceStartCfi, question.cfi);
    expect(anchor.sourceProgress, .4);
    expect(anchor.sourceTextSnapshot, isEmpty);
    expect(await repository.undo(mutation.action.id), UndoResult.undone);
    expect(await repository.artifacts(1), isEmpty);
    expect(await db.query('tb_reading_difficulties'), isEmpty);
    expect(await repository.undo(mutation.action.id), UndoResult.alreadyUndone);
    await expectLater(
        repository.saveDifficulty(question,
            sessionId: 's1', sourceProgress: .8, visibleFromProgress: .4),
        throwsArgumentError);
    expect(await db.query('tb_reading_difficulties'), isEmpty);
  });

  test('practice records capture relations, review history and bulk deletion',
      () async {
    final guide =
        InspectionReadingGuide(bookId: 1, note: 'Before', updatedAt: now);
    final guideAction = await repository.savePracticeRecord(
        kind: ReadingPracticeRecordKind.guide,
        bookId: 1,
        targetId: '1',
        values: guide.toDb(),
        sessionId: 's1');
    expect(await repository.undo(guideAction.action.id), UndoResult.undone);
    expect(await db.query('tb_reading_guides'), isEmpty);
    final source = ReadingMemorySource(
        id: 'source',
        bookId: 1,
        type: ReadingMemorySourceType.difficulty,
        sourceRef: 'difficulty',
        cfi: 'epubcfi(/6/2)',
        text: 'Record',
        contentHash: 'hash',
        createdAt: now);
    await repository.savePracticeRecord(
        kind: ReadingPracticeRecordKind.source,
        bookId: 1,
        targetId: source.id,
        values: source.toDb(),
        sessionId: 's1');
    final topic = ReadingMemoryTopic(
        id: 'topic',
        bookId: 1,
        title: 'Topic',
        summary: 'Summary',
        status: ReadingMemoryItemStatus.suggested,
        batchId: 'batch',
        sourceIds: ['source'],
        createdAt: now,
        updatedAt: now);
    await repository.savePracticeRecord(
        kind: ReadingPracticeRecordKind.topic,
        bookId: 1,
        targetId: topic.id,
        values: topic.toDb(),
        sourceIds: topic.sourceIds,
        sessionId: 's1');
    final card = ReadingKnowledgeCard(
        id: 'memory-card',
        bookId: 1,
        topicId: topic.id,
        question: 'Q',
        answer: 'A',
        status: ReadingMemoryItemStatus.active,
        sourceIds: ['source'],
        nextReviewAt: now,
        createdAt: now,
        updatedAt: now);
    await repository.savePracticeRecord(
        kind: ReadingPracticeRecordKind.card,
        bookId: 1,
        targetId: card.id,
        values: card.toDb(),
        sourceIds: card.sourceIds,
        sessionId: 's1');
    final review = ReadingCardReview(
        id: 'review',
        cardId: card.id,
        bookId: 1,
        rating: ReadingReviewRating.remembered,
        previousStage: 1,
        nextStage: 2,
        previousReviewAt: now,
        nextReviewAt: now + 1000,
        reviewedAt: now);
    final reviewed = await repository.savePracticeRecord(
        kind: ReadingPracticeRecordKind.card,
        bookId: 1,
        targetId: card.id,
        values: card.copyWith(reviewStage: 2, updatedAt: now + 1).toDb(),
        review: review.toDb(),
        expectedUpdatedAt: now,
        sessionId: 's1');
    expect(await db.query('tb_reading_card_reviews'), hasLength(1));
    expect(await repository.undo(reviewed.action.id), UndoResult.undone);
    expect(await db.query('tb_reading_card_reviews'), isEmpty);
    expect(
        (await db.query('tb_reading_knowledge_cards')).single['review_stage'],
        1);
    final cleared = await repository.deletePracticeMemory(1, sessionId: 's1');
    expect(await db.query('tb_reading_memory_sources'), isEmpty);
    expect(await db.query('tb_reading_card_sources'), isEmpty);
    expect(await repository.undo(cleared.action.id), UndoResult.undone);
    expect(await db.query('tb_reading_memory_sources'), hasLength(1));
    expect(await db.query('tb_reading_card_sources'), hasLength(1));
    await expectLater(
        repository.savePracticeRecord(
            kind: ReadingPracticeRecordKind.card,
            bookId: 2,
            targetId: card.id,
            values: card.toDb(),
            sessionId: 's2'),
        throwsStateError);
  });

  test('resolving a difficulty journals status instead of reopening it',
      () async {
    final original = ReadingDifficulty(
        id: 'difficulty',
        bookId: 1,
        cfi: 'epubcfi(/6/2)',
        text: 'Question',
        createdAt: now,
        updatedAt: now);
    await repository.saveDifficulty(original, sessionId: 's1');
    final resolved = await repository.updateDifficultyStatus(
        original.copyWith(
            status: ReadingDifficultyStatus.resolved, updatedAt: now + 1),
        sessionId: 's1');
    expect(resolved.value.status, ReadingDifficultyStatus.resolved);
    expect(await repository.undo(resolved.action.id), UndoResult.undone);
    final rows = await db.query('tb_reading_difficulties');
    expect(rows.single['status'], ReadingDifficultyStatus.unresolved.name);
  });

  test('replacing and undoing an active goal restores the prior goal',
      () async {
    await repository.saveGoal(goal('first'), sessionId: 's1');
    now += 1;
    final second = await repository.saveGoal(goal('second'), sessionId: 's1');

    expect((await repository.activeGoal(1))?.id, 'second');
    expect((await dao.goal('first'))?.status, ReadingGoalStatus.abandoned);

    expect(await repository.undo(second.action.id), UndoResult.undone);
    expect((await repository.activeGoal(1))?.id, 'first');
    expect(await dao.goal('second'), isNull);
    expect(await repository.undo(second.action.id), UndoResult.alreadyUndone);
  });

  test('goal undo refuses to overwrite a later user edit', () async {
    final mutation =
        await repository.saveGoal(goal('goal'), sessionId: 'session');
    await db.update('tb_reading_goals', {'title': 'User edited'},
        where: 'id = ?', whereArgs: ['goal']);

    expect(await repository.undo(mutation.action.id), UndoResult.conflict);
    expect((await dao.goal('goal'))?.title, 'User edited');
  });

  test('automatic goal progress keeps the originating action undoable',
      () async {
    final mutation =
        await repository.saveGoal(goal('progress-goal'), sessionId: 'session');
    now += 1;
    await repository.updateGoalProgress(
      mutation.value.copyWith(progress: .4, updatedAt: now),
    );

    expect((await dao.goal('progress-goal'))?.progress, .4);
    expect(await repository.undo(mutation.action.id), UndoResult.undone);
    expect(await dao.goal('progress-goal'), isNull);
  });

  test(
      'profile inference counts distinct sessions and confirmation is undoable',
      () async {
    for (final session in ['one', 'two', 'two', 'three']) {
      now += 1;
      await repository.recordProfileEvidence(
        key: 'explanationOrder',
        value: const {'value': 'exampleFirst'},
        sessionId: session,
      );
    }
    final candidate = (await repository.profileCandidates()).single;
    expect(candidate.evidenceCount, 3);
    expect(candidate.confidence, 1);

    final confirmed = await repository.setProfileStatus(
      key: candidate.key,
      status: ReaderProfileStatus.confirmed,
      sessionId: 'three',
    );
    expect((await repository.confirmedProfile()).single.key, candidate.key);
    expect(await repository.undo(confirmed.action.id), UndoResult.undone);
    expect((await repository.profileCandidates()).single.key, candidate.key);
  });

  test('rejected profile suppresses new evidence for 90 days', () async {
    await repository.recordProfileEvidence(
      key: 'teachingStyle',
      value: const {'value': 'direct'},
      sessionId: 'one',
    );
    await repository.setProfileStatus(
      key: 'teachingStyle',
      status: ReaderProfileStatus.rejected,
      sessionId: 'one',
    );
    final suppressed = await repository.recordProfileEvidence(
      key: 'teachingStyle',
      value: const {'value': 'socratic'},
      sessionId: 'two',
    );
    expect(suppressed, isNull);
  });

  test('reopening and undoing a difficulty restores resolved state', () async {
    final resolved = ReadingDifficulty(
      id: 'difficulty',
      bookId: 1,
      cfi: '/6/2',
      text: 'Dense paragraph',
      status: ReadingDifficultyStatus.resolved,
      createdAt: now,
      updatedAt: now,
    );
    await db.insert('tb_reading_difficulties', resolved.toDb());
    now += 1;
    final mutation = await repository.saveDifficulty(
      resolved.copyWith(updatedAt: now),
      sessionId: 'session',
    );
    expect(mutation.value.status, ReadingDifficultyStatus.unresolved);

    expect(await repository.undo(mutation.action.id), UndoResult.undone);
    final row = (await db.query('tb_reading_difficulties')).single;
    expect(
        ReadingDifficulty.fromDb(row).status, ReadingDifficultyStatus.resolved);
  });

  test('agent note requires source and undo removes the document', () async {
    final note = ReadingNote(
      id: 'note',
      bookId: 1,
      title: 'Explanation',
      status: ReadingNoteStatus.active,
      captureKind: ReadingNoteCaptureKind.question,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
    );
    final document = ReadingNoteDocument(
      note: note,
      blocks: [
        ReadingNoteBlock(
          id: 'block',
          noteId: note.id,
          type: ReadingNoteBlockType.ai,
          content: 'Agent explanation',
          sortOrder: 0,
          origin: ReadingNoteBlockOrigin.ai,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      sources: [
        ReadingNoteSource(
          noteId: note.id,
          type: ReadingNoteSourceType.aiSession,
          sourceRef: 'session',
          chapterTitle: 'Chapter 1',
          cfi: '/6/2',
          textSnapshot: 'Source text',
          metadata: const {'model': 'test'},
          createdAt: now,
        ),
      ],
    );
    final mutation =
        await repository.createNote(document, sessionId: 'session');
    expect(await db.query('tb_reading_notes'), hasLength(1));

    expect(await repository.undo(mutation.action.id), UndoResult.undone);
    expect(await db.query('tb_reading_notes'), isEmpty);
    expect(await db.query('tb_reading_note_blocks'), isEmpty);
    expect(await db.query('tb_reading_note_sources'), isEmpty);
  });

  test('agent note undo also removes its owned annotation', () async {
    final note = ReadingNote(
      id: 'owned-note',
      bookId: 1,
      title: 'Explanation',
      status: ReadingNoteStatus.active,
      captureKind: ReadingNoteCaptureKind.manual,
      isFavorite: false,
      createdAt: now,
      updatedAt: now,
    );
    final document = ReadingNoteDocument(
      note: note,
      sources: [
        ReadingNoteSource(
          noteId: note.id,
          type: ReadingNoteSourceType.aiSession,
          sourceRef: 'session',
          cfi: 'epubcfi(/6/2)',
          textSnapshot: 'Quoted source',
          createdAt: now,
        ),
      ],
    );
    final mutation = await repository.createNote(
      document,
      sessionId: 'session',
      ownedAnnotation: BookNote(
        bookId: 1,
        content: 'Quoted source',
        cfi: 'epubcfi(/6/2)',
        chapter: 'Chapter',
        type: 'highlight',
        color: '66CCFF',
        createTime: DateTime.fromMillisecondsSinceEpoch(now),
        updateTime: DateTime.fromMillisecondsSinceEpoch(now),
      ),
    );

    expect(await db.query('tb_notes'), hasLength(1));
    expect(await repository.undo(mutation.action.id), UndoResult.undone);
    expect(await db.query('tb_notes'), isEmpty);
    expect(await db.query('tb_reading_notes'), isEmpty);
  });

  test(
      'chapter closure persists mastery, due card, and undoable markdown memory',
      () async {
    final checkpoint = ReadingChapterCheckpoint(
        id: 'checkpoint',
        bookId: 1,
        chapterHref: 'one.xhtml',
        chapterTitle: 'One',
        progress: .95,
        createdAt: now,
        updatedAt: now);
    await repository.upsertCheckpoint(checkpoint);
    await repository.completeCheckpoint(checkpoint,
        completed: true, reflection: 'Core argument');
    await repository.saveMastery(MasteryState(
        id: 'mastery',
        bookId: 1,
        chapterHref: 'one.xhtml',
        topic: 'One',
        level: MasteryLevel.familiar,
        score: .66,
        nextReviewAt: now,
        updatedAt: now));
    await repository.saveKnowledgeCard(KnowledgeCard(
        id: 'card',
        bookId: 1,
        front: 'Recall',
        back: 'Core argument',
        dueAt: now,
        createdAt: now,
        updatedAt: now));
    final memory = await repository.appendMemory(
        ReadingMemoryDocument(
            id: 'memory',
            bookId: 1,
            title: 'Argument map',
            markdown: '# Argument\n- Premise',
            createdAt: now,
            updatedAt: now),
        sessionId: 'session');

    expect(await repository.pendingCheckpoints(1), isEmpty);
    expect((await repository.masteryStates(1)).single.level,
        MasteryLevel.familiar);
    expect(await repository.dueKnowledgeCards(1), hasLength(1));
    expect((await repository.memoryDocuments(1)).single.markdown,
        contains('# Argument'));
    expect(await repository.undo(memory.action.id), UndoResult.undone);
    expect(await repository.memoryDocuments(1), isEmpty);
  });

  test('source-backed artifact is progress-bounded and undoable', () async {
    final mutation = await repository.saveArtifact(
      ReadingArtifact(
        id: 'character',
        bookId: 1,
        moduleId: 'fiction.immersion',
        kind: ReadingArtifactKinds.character,
        payload: const {'name': '林先生', 'summary': '在车站出现'},
        sourceStartCfi: 'epubcfi(/6/4)',
        sourceTextSnapshot: '林先生站在月台上。',
        discoveredAtCfi: 'epubcfi(/6/4)',
        sourceProgress: .4,
        visibleFromProgress: .4,
        ingestedAt: now,
        createdAt: now,
        updatedAt: now,
      ),
      sessionId: 'session',
    );

    expect(await repository.artifacts(1, visibleAtProgress: .39), isEmpty);
    expect(await repository.artifacts(1, visibleAtProgress: .4), hasLength(1));
    expect(await repository.undo(mutation.action.id), UndoResult.undone);
    expect(await repository.artifacts(1), isEmpty);
  });
}
