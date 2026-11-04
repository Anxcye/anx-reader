import 'dart:convert';

import 'package:anx_reader/dao/reading_agent.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/reading_coach.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/service/ai/reading_source_anchor_validator.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

const supportedReaderProfileKeys = {
  'explanationDepth',
  'explanationOrder',
  'teachingStyle',
  'outputStructure',
  'interruptionTolerance',
};

enum ReadingPracticeRecordKind {
  guide('tb_reading_guides', 'book_id'),
  quiz('tb_reading_quizzes', 'id'),
  topic('tb_reading_memory_topics', 'id'),
  card('tb_reading_knowledge_cards', 'id'),
  source('tb_reading_memory_sources', 'id');

  const ReadingPracticeRecordKind(this.table, this.key);
  final String table;
  final String key;
}

class ReadingAgentRepository {
  ReadingAgentRepository({
    ReadingAgentDao? dao,
    Uuid? uuid,
    int Function()? clock,
  })  : _dao = dao ?? readingAgentDao,
        _uuid = uuid ?? const Uuid(),
        _clock = clock ?? (() => DateTime.now().millisecondsSinceEpoch);

  static const retention = Duration(days: 30);
  static const rejectionSuppression = Duration(days: 90);
  static const maxActions = 200;

  final ReadingAgentDao _dao;
  final Uuid _uuid;
  final int Function() _clock;

  Future<ReadingGoal?> activeGoal(int bookId) => _dao.activeGoal(bookId);
  Future<BookReadingCoverage?> bookReadingCoverage(int bookId) =>
      _dao.bookReadingCoverage(bookId);
  Future<void> saveBookReadingCoverage(BookReadingCoverage coverage) =>
      _dao.saveBookReadingCoverage(coverage);
  Future<List<ReadingGoal>> goals(int bookId) => _dao.goals(bookId);
  Future<List<ReadingChapterCheckpoint>> pendingCheckpoints(int bookId) =>
      _dao.pendingCheckpoints(bookId);
  Future<List<MasteryState>> masteryStates(int bookId) =>
      _dao.masteryStates(bookId);
  Future<List<KnowledgeCard>> dueKnowledgeCards(int bookId) =>
      _dao.dueKnowledgeCards(bookId, _clock());
  Future<List<KnowledgeCard>> knowledgeCards(int bookId) =>
      _dao.knowledgeCards(bookId);
  Future<List<ReadingMemoryDocument>> memoryDocuments(int bookId) =>
      _dao.memoryDocuments(bookId);
  Future<List<ReadingArtifact>> artifacts(
    int bookId, {
    String? kind,
    ReadingArtifactStatus? status,
    double? visibleAtProgress,
  }) =>
      _dao.artifacts(
        bookId,
        kind: kind,
        status: status,
        visibleAtProgress: visibleAtProgress,
      );

  Future<BookWiki?> bookWiki(int bookId) => _dao.wiki(bookId);
  Future<List<BookWikiEntry>> bookWikiEntries(int bookId,
          {double? visibleAtProgress}) =>
      _dao.wikiEntries(bookId, visibleAtProgress: visibleAtProgress);
  Future<List<BookWikiSourceRef>> bookWikiSources(String entryId) =>
      _dao.wikiSources(entryId);

  Future<AgentMutation<BookWikiEntry>> saveWikiEntry(
    BookWikiEntry entry, {
    required String sessionId,
    BookWiki? wiki,
    BookWikiRevision? revision,
  }) async {
    if (entry.id.isEmpty ||
        entry.bookId <= 0 ||
        entry.title.trim().isEmpty ||
        !BookWikiEntryKinds.supported.contains(entry.kind)) {
      throw ArgumentError(
          'Wiki entry requires a supported kind, identity and title');
    }
    if (entry.sources.isEmpty && entry.sourceArtifactIds.isEmpty) {
      throw ArgumentError('Wiki entry requires a traceable source');
    }
    final now = _clock();
    return _dao.write((txn) async {
      final before = await _wikiSnapshot(txn, entry.id);
      final currentEntry = before?['entry'];
      if (currentEntry is Map &&
          currentEntry['user_corrected'] == 1 &&
          !entry.userCorrected) {
        return AgentMutation(
          value: BookWikiEntry.fromDb(Map<String, dynamic>.from(currentEntry)),
          action: _action(
              type: AgentActionType.wiki,
              targetId: entry.id,
              bookId: entry.bookId,
              sessionId: sessionId,
              before: before,
              after: before,
              now: now),
        );
      }
      await txn.insert('tb_book_wiki_entries', entry.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await txn.delete('tb_book_wiki_entry_sources',
          where: 'entry_id = ?', whereArgs: [entry.id]);
      for (final source in entry.sources) {
        await txn.insert('tb_book_wiki_entry_sources', source.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      if (wiki != null) {
        await txn.insert('tb_book_wikis', wiki.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      if (revision != null) {
        await txn.insert('tb_book_wiki_revisions', revision.toDb(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      final after = await _wikiSnapshot(txn, entry.id);
      final action = _action(
          type: AgentActionType.wiki,
          targetId: entry.id,
          bookId: entry.bookId,
          sessionId: sessionId,
          before: before,
          after: after,
          now: now);
      await _insertAction(txn, action, now);
      return AgentMutation(value: entry, action: action);
    });
  }

  Future<ReadingChapterCheckpoint> upsertCheckpoint(
      ReadingChapterCheckpoint checkpoint) async {
    await _dao.write((txn) async {
      await txn.insert('tb_reading_checkpoints', checkpoint.toDb(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
    });
    return checkpoint;
  }

  Future<ReadingChapterCheckpoint> completeCheckpoint(
      ReadingChapterCheckpoint checkpoint,
      {required bool completed,
      String reflection = ''}) async {
    final updated = checkpoint.copyWith(
        status: completed
            ? ReadingCheckpointStatus.completed
            : ReadingCheckpointStatus.skipped,
        reflection: reflection,
        updatedAt: _clock());
    await _dao.write((txn) async {
      await txn.insert('tb_reading_checkpoints', updated.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace);
    });
    return updated;
  }

  Future<AgentMutation<ReadingChapterCheckpoint>> finishChapterCheckpoint({
    required ReadingChapterCheckpoint checkpoint,
    MasteryState? mastery,
    KnowledgeCard? card,
    ReadingMemoryDocument? memory,
    required String sessionId,
  }) =>
      _dao.write((txn) async {
        final stored = await _queryOne(
            txn, 'tb_reading_checkpoints', 'id = ?', [checkpoint.id]);
        if (stored == null ||
            stored['book_id'] != checkpoint.bookId ||
            stored['chapter_href'] != checkpoint.chapterHref ||
            (stored['progress'] as num).toDouble() != checkpoint.progress ||
            !checkpoint.progress.isFinite ||
            checkpoint.progress < 0 ||
            checkpoint.progress > 1 ||
            checkpoint.chapterHref.isEmpty ||
            stored['updated_at'] != checkpoint.updatedAt ||
            stored['status'] != ReadingCheckpointStatus.pending.name ||
            (mastery != null &&
                (mastery.bookId != checkpoint.bookId ||
                    mastery.chapterHref != checkpoint.chapterHref)) ||
            (card != null &&
                (card.bookId != checkpoint.bookId ||
                    card.chapterHref != checkpoint.chapterHref)) ||
            (memory != null &&
                (memory.bookId != checkpoint.bookId ||
                    memory.sourceRefs.length != 1 ||
                    memory.sourceRefs.single !=
                        'checkpoint:${checkpoint.id}'))) {
          throw StateError(
              'Checkpoint identity, boundary or state changed before completion');
        }
        final now = _clock();
        final updated = checkpoint.copyWith(
            status: ReadingCheckpointStatus.completed, updatedAt: now);
        final anchors = <ReadingArtifact>[];
        for (final (kind, id) in <(String, String)>[
          ('checkpoint', checkpoint.id),
          if (mastery != null) ('mastery', mastery.id),
          if (card != null) ('knowledgeCard', card.id),
        ]) {
          final anchor = ReadingArtifact(
              id: 'source-anchor:$kind:$id',
              bookId: checkpoint.bookId,
              moduleId: 'reading.sources',
              kind: ReadingArtifactKinds.sourceAnchor,
              payload: {
                'sourceKind': kind,
                'sourceId': id,
                'checkpointId': checkpoint.id
              },
              epistemicStatus: ReadingArtifactEpistemicStatus.userReflection,
              chapterHref: checkpoint.chapterHref,
              sourceProgress: checkpoint.progress,
              visibleFromProgress: checkpoint.progress,
              ingestedAt: now,
              sessionId: sessionId,
              createdAt: now,
              updatedAt: now);
          ReadingSourceAnchorValidator.validate(anchor);
          anchors.add(anchor);
        }
        final descriptor = <String, dynamic>{
          'checkpoint': checkpoint.id,
          if (mastery != null) 'mastery': mastery.id,
          if (card != null) 'card': card.id,
          if (memory != null) 'memory': memory.id,
          'anchors': anchors.map((anchor) => anchor.id).toList()
        };
        final before = await _chapterClosureSnapshot(txn, descriptor);
        for (final (table, row) in <(String, Map<String, Object?>)>[
          ('tb_reading_checkpoints', updated.toDb()),
          if (mastery != null) ('tb_reading_mastery', mastery.toDb()),
          if (card != null) ('tb_knowledge_cards', card.toDb()),
          if (memory != null) ('tb_reading_memory_documents', memory.toDb()),
          for (final anchor in anchors) ('tb_reading_artifacts', anchor.toDb()),
        ]) {
          if (row['book_id'] != checkpoint.bookId) {
            throw StateError('Closure belongs to another book');
          }
          final existing = await _queryOne(txn, table, 'id = ?', [row['id']]);
          if (existing != null && existing['book_id'] != checkpoint.bookId) {
            throw StateError('Closure target belongs to another book');
          }
          await txn.insert(table, row,
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        final after = await _chapterClosureSnapshot(txn, descriptor);
        final action = _action(
            type: AgentActionType.memory,
            targetId: checkpoint.id,
            bookId: checkpoint.bookId,
            sessionId: sessionId,
            before: before,
            after: after,
            now: now);
        await _insertAction(txn, action, now);
        return AgentMutation(value: updated, action: action);
      });

  static const _closureTables = {
    'checkpoint': 'tb_reading_checkpoints',
    'mastery': 'tb_reading_mastery',
    'card': 'tb_knowledge_cards',
    'memory': 'tb_reading_memory_documents'
  };

  Future<Map<String, dynamic>> _chapterClosureSnapshot(
          Transaction txn, Map<String, dynamic> descriptor) async =>
      {
        'chapterClosure': descriptor,
        for (final entry in _closureTables.entries)
          if (descriptor[entry.key] != null)
            entry.key: await _queryOne(
                txn, entry.value, 'id = ?', [descriptor[entry.key]]),
        'anchors': [
          for (final id in descriptor['anchors'] as List)
            await _queryOne(txn, 'tb_reading_artifacts', 'id = ?', [id])
        ],
      };

  Future<MasteryState> saveMastery(MasteryState state) async {
    await _dao.write((txn) async => txn.insert(
        'tb_reading_mastery', state.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace));
    return state;
  }

  Future<KnowledgeCard> saveKnowledgeCard(KnowledgeCard card) async {
    await _dao.write((txn) async => txn.insert(
        'tb_knowledge_cards', card.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace));
    return card;
  }

  Future<AgentMutation<KnowledgeCard>> reviewKnowledgeCard(
    KnowledgeCard card, {
    required String sessionId,
    int? expectedUpdatedAt,
  }) =>
      _dao.write((txn) async {
        final before =
            await _queryOne(txn, 'tb_knowledge_cards', 'id = ?', [card.id]);
        if (before == null || before['book_id'] != card.bookId) {
          throw StateError('Knowledge card is unavailable for this book');
        }
        if (expectedUpdatedAt != null &&
            before['updated_at'] != expectedUpdatedAt) {
          throw StateError('Knowledge card changed before this review');
        }
        await txn.update('tb_knowledge_cards', card.toDb(),
            where: 'id = ?', whereArgs: [card.id]);
        final action = _action(
          type: AgentActionType.memory,
          targetId: card.id,
          bookId: card.bookId,
          sessionId: sessionId,
          before: {'knowledgeCard': before},
          after: {'knowledgeCard': card.toDb()},
          now: _clock(),
        );
        await _insertAction(txn, action, _clock());
        return AgentMutation(value: card, action: action);
      });

  /// Registered practice records reuse the existing memory action journal.
  /// A review and its schedule, or a kept topic and its note backlinks, are
  /// captured and restored together in one transaction.
  Future<AgentMutation<Map<String, Object?>>> savePracticeRecord({
    required ReadingPracticeRecordKind kind,
    required int bookId,
    required String targetId,
    required Map<String, Object?> values,
    required String sessionId,
    Map<String, Object?>? review,
    List<String>? sourceIds,
    int? expectedUpdatedAt,
    bool createOnly = false,
  }) =>
      _dao.write((txn) async {
        final before = await _practiceSnapshot(txn, kind, targetId,
            reviewId: review?['id']?.toString());
        final row = before['row'] as Map?;
        if ((row != null && row['book_id'] != bookId) ||
            values['book_id'] != bookId ||
            (values[kind.key] != null &&
                values[kind.key].toString() != targetId) ||
            (review != null &&
                (review['book_id'] != bookId ||
                    review['card_id'] != targetId))) {
          throw StateError('Practice record belongs to another book');
        }
        if (expectedUpdatedAt != null &&
            row?['updated_at'] != expectedUpdatedAt) {
          throw StateError('Practice record changed before this action');
        }
        final saved = <String, Object?>{
          if (row != null) ...Map<String, Object?>.from(row),
          if (!createOnly || row == null) ...values
        };
        if (kind == ReadingPracticeRecordKind.guide && row != null) {
          final incoming = values['report'];
          if (incoming == null) {
            saved['report'] = row['report'];
          } else {
            final parsed = jsonDecode(incoming.toString());
            if (parsed is Map &&
                !parsed.containsKey('sourceProgress') &&
                parsed.keys
                    .every((key) => key.toString().startsWith('synthesis'))) {
              final previous = row['report'] == null
                  ? const {}
                  : jsonDecode(row['report'].toString());
              saved['report'] =
                  jsonEncode({if (previous is Map) ...previous, ...parsed});
            }
          }
        }
        await txn.insert(kind.table, saved,
            conflictAlgorithm: ConflictAlgorithm.replace);
        if (sourceIds != null && (!createOnly || row == null)) {
          final (table, key) = kind == ReadingPracticeRecordKind.topic
              ? ('tb_reading_topic_sources', 'topic_id')
              : ('tb_reading_card_sources', 'card_id');
          if (kind != ReadingPracticeRecordKind.topic &&
              kind != ReadingPracticeRecordKind.card) {
            throw ArgumentError('Only topics and cards have source relations');
          }
          await txn.delete(table, where: '$key = ?', whereArgs: [targetId]);
          for (final source in sourceIds.toSet()) {
            final stored = await _queryOne(
                txn, 'tb_reading_memory_sources', 'id = ?', [source]);
            if (stored?['book_id'] != bookId) {
              throw StateError('Unknown memory source');
            }
            await txn.insert(table, {key: targetId, 'source_id': source});
          }
        }
        if (review != null) await txn.insert('tb_reading_card_reviews', review);
        if (kind == ReadingPracticeRecordKind.topic &&
            saved['status'] == 'kept') {
          final sources = await txn.rawQuery(
              '''SELECT s.* FROM tb_reading_memory_sources s
        JOIN tb_reading_topic_sources ts ON ts.source_id = s.id
        JOIN tb_reading_notes n ON n.id = s.source_ref AND n.book_id = s.book_id
        WHERE ts.topic_id = ? AND s.book_id = ? AND s.source_type = ?''',
              [targetId, bookId, 'readingNote']);
          for (final source in sources) {
            await txn.insert(
                'tb_reading_note_sources',
                ReadingNoteSource(
                  noteId: source['source_ref'].toString(),
                  type: ReadingNoteSourceType.memoryTopic,
                  sourceRef: targetId,
                  chapterHref: source['chapter_href'] as String?,
                  chapterTitle: source['chapter_title'] as String?,
                  cfi: source['cfi'] as String?,
                  textSnapshot: source['text_snapshot'].toString(),
                  createdAt: _clock(),
                ).toDb(),
                conflictAlgorithm: ConflictAlgorithm.replace);
          }
        }
        final after = await _practiceSnapshot(txn, kind, targetId,
            reviewId: review?['id']?.toString());
        final action = _action(
            type: AgentActionType.memory,
            targetId: targetId,
            bookId: bookId,
            sessionId: sessionId,
            before: before,
            after: after,
            now: _clock());
        await _insertAction(txn, action, _clock());
        return AgentMutation(value: saved, action: action);
      });

  Future<Map<String, dynamic>> _practiceSnapshot(
          Transaction txn, ReadingPracticeRecordKind kind, String targetId,
          {String? reviewId}) async =>
      {
        'practice': kind.name,
        'row': await _queryOne(txn, kind.table, '${kind.key} = ?', [targetId]),
        if (reviewId != null) ...{
          'reviewId': reviewId,
          'review': await _queryOne(
              txn, 'tb_reading_card_reviews', 'id = ?', [reviewId]),
        },
        if (kind == ReadingPracticeRecordKind.topic)
          'noteSources': await txn.query('tb_reading_note_sources',
              where: 'source_type = ? AND source_ref = ?',
              whereArgs: ['memoryTopic', targetId],
              orderBy: 'note_id'),
        if (kind == ReadingPracticeRecordKind.topic ||
            kind == ReadingPracticeRecordKind.card)
          'sourceIds': await txn.query(
              kind == ReadingPracticeRecordKind.topic
                  ? 'tb_reading_topic_sources'
                  : 'tb_reading_card_sources',
              columns: ['source_id'],
              where: kind == ReadingPracticeRecordKind.topic
                  ? 'topic_id = ?'
                  : 'card_id = ?',
              whereArgs: [targetId],
              orderBy: 'source_id'),
      };

  Future<Map<String, dynamic>> _memoryBookSnapshot(
          Transaction txn, int bookId) async =>
      {
        'practiceMemoryBook': bookId,
        'rows': {
          for (final table in const [
            'tb_reading_memory_sources',
            'tb_reading_memory_topics',
            'tb_reading_knowledge_cards',
            'tb_reading_card_reviews'
          ])
            table: await txn.query(table,
                where: 'book_id = ?', whereArgs: [bookId], orderBy: 'id'),
          'tb_reading_topic_sources': await txn.rawQuery(
              '''SELECT s.* FROM tb_reading_topic_sources s
        JOIN tb_reading_memory_topics t ON t.id = s.topic_id WHERE t.book_id = ? ORDER BY topic_id, source_id''',
              [bookId]),
          'tb_reading_card_sources': await txn.rawQuery(
              '''SELECT s.* FROM tb_reading_card_sources s
        JOIN tb_reading_knowledge_cards c ON c.id = s.card_id WHERE c.book_id = ? ORDER BY card_id, source_id''',
              [bookId]),
          'tb_reading_note_sources':
              await txn.rawQuery('''SELECT s.* FROM tb_reading_note_sources s
        JOIN tb_reading_notes n ON n.id = s.note_id WHERE n.book_id = ? AND s.source_type = ?
        ORDER BY note_id, source_type, source_ref''', [bookId, 'memoryTopic']),
        },
      };

  Future<void> _clearMemoryBook(Transaction txn, int bookId) async {
    await txn
        .rawDelete('''DELETE FROM tb_reading_topic_sources WHERE topic_id IN
      (SELECT id FROM tb_reading_memory_topics WHERE book_id = ?)''', [bookId]);
    await txn.rawDelete('''DELETE FROM tb_reading_card_sources WHERE card_id IN
      (SELECT id FROM tb_reading_knowledge_cards WHERE book_id = ?)''',
        [bookId]);
    await txn.rawDelete(
        '''DELETE FROM tb_reading_note_sources WHERE source_type = ?
      AND note_id IN (SELECT id FROM tb_reading_notes WHERE book_id = ?)''',
        ['memoryTopic', bookId]);
    for (final table in const [
      'tb_reading_card_reviews',
      'tb_reading_knowledge_cards',
      'tb_reading_memory_topics',
      'tb_reading_memory_sources'
    ]) {
      await txn.delete(table, where: 'book_id = ?', whereArgs: [bookId]);
    }
  }

  Future<AgentMutation<int>> deletePracticeMemory(int bookId,
          {required String sessionId}) =>
      _dao.write((txn) async {
        final before = await _memoryBookSnapshot(txn, bookId);
        await _clearMemoryBook(txn, bookId);
        final after = await _memoryBookSnapshot(txn, bookId);
        final action = _action(
            type: AgentActionType.memory,
            targetId: 'practice-memory:$bookId',
            bookId: bookId,
            sessionId: sessionId,
            before: before,
            after: after,
            now: _clock());
        await _insertAction(txn, action, _clock());
        return AgentMutation(value: bookId, action: action);
      });

  Future<AgentMutation<ReadingMemoryDocument>> appendMemory(
      ReadingMemoryDocument document,
      {required String sessionId}) async {
    if (document.bookId <= 0 || document.markdown.trim().isEmpty) {
      throw ArgumentError('Markdown memory requires a book and content');
    }
    final now = _clock();
    return _dao.write((txn) async {
      final before = await _queryOne(
          txn, 'tb_reading_memory_documents', 'id = ?', [document.id]);
      await txn.insert('tb_reading_memory_documents', document.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      final action = _action(
          type: AgentActionType.memory,
          targetId: document.id,
          bookId: document.bookId,
          sessionId: sessionId,
          before: before,
          after: document.toDb(),
          now: now);
      await _insertAction(txn, action, now);
      return AgentMutation(value: document, action: action);
    });
  }

  Future<AgentMutation<ReadingArtifact>> saveArtifact(
    ReadingArtifact artifact, {
    required String sessionId,
  }) async {
    if (artifact.kind == ReadingArtifactKinds.sourceAnchor) {
      ReadingSourceAnchorValidator.validate(artifact);
    }
    if (artifact.id.isEmpty ||
        artifact.bookId <= 0 ||
        artifact.moduleId.trim().isEmpty ||
        artifact.kind.trim().isEmpty ||
        artifact.payload.isEmpty) {
      throw ArgumentError('Reading artifact requires identity and payload');
    }
    if ((artifact.discoveredAtCfi?.trim().isEmpty ?? true) &&
        (artifact.chapterHref?.trim().isEmpty ?? true) &&
        artifact.sourceTextSnapshot.trim().isEmpty) {
      throw ArgumentError('Reading artifact requires a traceable source');
    }
    final now = _clock();
    return _dao.write((txn) async {
      final before =
          await _queryOne(txn, 'tb_reading_artifacts', 'id = ?', [artifact.id]);
      await txn.insert('tb_reading_artifacts', artifact.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      await _expandArtifactCoverage(txn, artifact);
      final action = _action(
        type: AgentActionType.artifact,
        targetId: artifact.id,
        bookId: artifact.bookId,
        sessionId: sessionId,
        before: before,
        after: artifact.toDb(),
        now: now,
      );
      await _insertAction(txn, action, now);
      return AgentMutation(value: artifact, action: action);
    });
  }

  /// Persists deterministic local reader state (for example the last settled
  /// fiction location). This is not AI-authored content and therefore does not
  /// create an Agent undo entry.
  Future<ReadingArtifact> saveSystemArtifact(ReadingArtifact artifact) async {
    if (artifact.kind == ReadingArtifactKinds.sourceAnchor) {
      ReadingSourceAnchorValidator.validate(artifact);
    }
    if (artifact.id.isEmpty ||
        artifact.bookId <= 0 ||
        artifact.payload.isEmpty) {
      throw ArgumentError('System artifact requires identity and payload');
    }
    await _dao.write((txn) async {
      await txn.insert(
        'tb_reading_artifacts',
        artifact.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      await _expandArtifactCoverage(txn, artifact);
    });
    return artifact;
  }

  /// Location-derived progress is not a separate Agent action. Advance the
  /// latest goal-action snapshot with it so ordinary reading does not make an
  /// otherwise valid undo conflict immediately.
  Future<void> updateGoalProgress(ReadingGoal goal) => _dao.write((txn) async {
        await txn.update(
          'tb_reading_goals',
          {'progress': goal.progress, 'updated_at': goal.updatedAt},
          where: "id = ? AND status = 'active'",
          whereArgs: [goal.id],
        );
        final current = await _queryOne(
          txn,
          'tb_reading_goals',
          'id = ?',
          [goal.id],
        );
        if (current == null) return;
        final actions = await txn.query(
          'tb_agent_actions',
          where:
              "action_type = 'goal' AND target_id = ? AND status = 'applied'",
          whereArgs: [goal.id],
          orderBy: 'created_at DESC',
          limit: 1,
        );
        if (actions.isEmpty) return;
        await txn.update(
          'tb_agent_actions',
          {
            'after_snapshot': jsonEncode(current),
            'after_hash': _hash(current),
          },
          where: 'id = ?',
          whereArgs: [actions.first['id']],
        );
      });
  Future<List<ReaderProfileItem>> confirmedProfile() =>
      _dao.profileItems(status: ReaderProfileStatus.confirmed);
  Future<List<ReaderProfileItem>> profileCandidates() async =>
      (await _dao.profileItems(status: ReaderProfileStatus.candidate))
          .where((item) => item.confidence >= 1)
          .toList(growable: false);
  Future<List<AgentAction>> recentActions({int? bookId}) => _dao.recentActions(
        bookId: bookId,
        createdAfter: _clock() - retention.inMilliseconds,
        limit: maxActions,
      );

  Future<AgentMutation<ReadingGoal>> saveGoal(
    ReadingGoal goal, {
    required String sessionId,
  }) async {
    _validateGoal(goal);
    final now = _clock();
    return _dao.write((txn) async {
      final previousActive = await _queryOne(
        txn,
        'tb_reading_goals',
        "book_id = ? AND status = 'active'",
        [goal.bookId],
      );
      final targetBefore =
          await _queryOne(txn, 'tb_reading_goals', 'id = ?', [goal.id]);
      if (goal.status == ReadingGoalStatus.active) {
        await txn.update(
          'tb_reading_goals',
          {'status': ReadingGoalStatus.abandoned.name, 'updated_at': now},
          where: "book_id = ? AND status = 'active' AND id != ?",
          whereArgs: [goal.bookId, goal.id],
        );
      }
      await txn.insert('tb_reading_goals', goal.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      final action = _action(
        type: AgentActionType.goal,
        targetId: goal.id,
        bookId: goal.bookId,
        sessionId: sessionId,
        before: {
          'target': targetBefore,
          'previousActive': previousActive,
        },
        after: goal.toDb(),
        now: now,
      );
      await _insertAction(txn, action, now);
      return AgentMutation(value: goal, action: action);
    });
  }

  /// Records one independent signal. Inferred preferences remain candidates;
  /// callers may surface them after three distinct session ids.
  Future<AgentMutation<ReaderProfileItem>?> recordProfileEvidence({
    required String key,
    required Map<String, dynamic> value,
    required String sessionId,
    bool explicit = false,
  }) async {
    _validateProfileKey(key);
    final now = _clock();
    return _dao.write((txn) async {
      final before = await _queryOne(
          txn, 'tb_reader_profile_items', 'profile_key = ?', [key]);
      final existing = before == null ? null : ReaderProfileItem.fromDb(before);
      if (existing?.status == ReaderProfileStatus.rejected &&
          (existing!.rejectedUntil ?? 0) > now) {
        return null;
      }
      final sameValue =
          existing != null && _hash(existing.value) == _hash(value);
      final sessions = <String>{
        if (sameValue) ...existing.evidenceSessionIds,
        sessionId,
      };
      final confidence =
          explicit ? 1.0 : (sessions.length / 3).clamp(0, 1).toDouble();
      final item = ReaderProfileItem(
        key: key,
        value: value,
        status: ReaderProfileStatus.candidate,
        confidence: confidence,
        evidenceSessionIds: sessions.toList(growable: false)..sort(),
        createdAt: existing?.createdAt ?? now,
        updatedAt: now,
      );
      await txn.insert('tb_reader_profile_items', item.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      final action = _action(
        type: AgentActionType.profile,
        targetId: key,
        sessionId: sessionId,
        before: before,
        after: item.toDb(),
        now: now,
      );
      await _insertAction(txn, action, now);
      return AgentMutation(value: item, action: action);
    });
  }

  Future<AgentMutation<ReaderProfileItem>> setProfileStatus({
    required String key,
    required ReaderProfileStatus status,
    required String sessionId,
  }) async {
    _validateProfileKey(key);
    final now = _clock();
    return _dao.write((txn) async {
      final before = await _queryOne(
          txn, 'tb_reader_profile_items', 'profile_key = ?', [key]);
      if (before == null) throw StateError('Unknown reader profile item: $key');
      final existing = ReaderProfileItem.fromDb(before);
      final item = existing.copyWith(
        status: status,
        confidence:
            status == ReaderProfileStatus.confirmed ? 1 : existing.confidence,
        rejectedUntil: status == ReaderProfileStatus.rejected
            ? now + rejectionSuppression.inMilliseconds
            : null,
        clearRejectedUntil: status != ReaderProfileStatus.rejected,
        updatedAt: now,
      );
      await txn.update('tb_reader_profile_items', item.toDb(),
          where: 'profile_key = ?', whereArgs: [key]);
      final action = _action(
        type: AgentActionType.profile,
        targetId: key,
        sessionId: sessionId,
        before: before,
        after: item.toDb(),
        now: now,
      );
      await _insertAction(txn, action, now);
      return AgentMutation(value: item, action: action);
    });
  }

  Future<AgentMutation<ReadingNoteDocument>> createNote(
    ReadingNoteDocument document, {
    required String sessionId,
    int? ownedAnnotationId,
    BookNote? ownedAnnotation,
  }) async {
    if (document.sources.isEmpty ||
        document.sources.every((source) =>
            source.textSnapshot.trim().isEmpty &&
            (source.cfi?.trim().isEmpty ?? true))) {
      throw ArgumentError('Agent notes require a traceable source');
    }
    if (document.note.id.isEmpty || document.note.bookId <= 0) {
      throw ArgumentError('Invalid reading note');
    }
    final now = _clock();
    return _dao.write((txn) async {
      final existing = await _queryOne(
          txn, 'tb_reading_notes', 'id = ?', [document.note.id]);
      if (existing != null) throw StateError('Reading note already exists');
      var annotationId = ownedAnnotationId;
      if (ownedAnnotation != null) {
        annotationId = await txn.insert('tb_notes', ownedAnnotation.toMap());
        ownedAnnotation.id = annotationId;
      }
      await _insertDocument(txn, document);
      final after = await _noteSnapshot(txn, document.note.id);
      if (annotationId != null) {
        after!['ownedAnnotationId'] = annotationId;
      }
      final action = _action(
        type: AgentActionType.note,
        targetId: document.note.id,
        bookId: document.note.bookId,
        sessionId: sessionId,
        before: null,
        after: after,
        now: now,
      );
      await _insertAction(txn, action, now);
      return AgentMutation(value: document, action: action);
    });
  }

  Future<AgentMutation<ReadingDifficulty>> saveDifficulty(
    ReadingDifficulty difficulty, {
    required String sessionId,
    double? sourceProgress,
    double? visibleFromProgress,
  }) async {
    if (difficulty.bookId <= 0 ||
        difficulty.cfi.trim().isEmpty ||
        difficulty.text.trim().isEmpty) {
      throw ArgumentError('Difficulty requires book, CFI, and selected text');
    }
    final now = _clock();
    return _dao.write((txn) async {
      final before = await _queryOne(
        txn,
        'tb_reading_difficulties',
        'book_id = ? AND cfi = ? AND selected_text = ?',
        [difficulty.bookId, difficulty.cfi, difficulty.text],
      );
      final existing = before == null ? null : ReadingDifficulty.fromDb(before);
      final saved = existing == null
          ? difficulty
          : existing.status == ReadingDifficultyStatus.resolved
              ? existing.copyWith(
                  status: ReadingDifficultyStatus.unresolved, updatedAt: now)
              : existing;
      await txn.insert('tb_reading_difficulties', saved.toDb(),
          conflictAlgorithm: ConflictAlgorithm.replace);
      Map<String, Object?>? anchorBefore;
      ReadingArtifact? anchor;
      if (sourceProgress != null) {
        final anchorId = 'source-anchor:difficulty:${saved.id}';
        anchorBefore =
            await _queryOne(txn, 'tb_reading_artifacts', 'id = ?', [anchorId]);
        anchor = ReadingArtifact(
            id: anchorId,
            bookId: saved.bookId,
            moduleId: 'reading.sources',
            kind: ReadingArtifactKinds.sourceAnchor,
            payload: {'sourceKind': 'difficulty', 'sourceId': saved.id},
            epistemicStatus: ReadingArtifactEpistemicStatus.userReflection,
            sourceStartCfi: saved.cfi,
            sourceEndCfi: saved.cfi,
            discoveredAtCfi: saved.cfi,
            sourceProgress: sourceProgress,
            visibleFromProgress: visibleFromProgress ?? sourceProgress,
            ingestedAt: now,
            sessionId: sessionId,
            createdAt: now,
            updatedAt: now);
        ReadingSourceAnchorValidator.validate(anchor);
        await txn.insert('tb_reading_artifacts', anchor.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      final action = _action(
        type: AgentActionType.difficulty,
        targetId: saved.id,
        bookId: saved.bookId,
        sessionId: sessionId,
        before: anchor == null
            ? before
            : {
                if (before != null) ...before,
                '_difficultyExisted': before != null,
                '_sourceAnchor': anchorBefore,
              },
        after: {
          ...saved.toDb(),
          if (anchor != null) ...{
            '_difficultyExisted': true,
            '_sourceAnchor': anchor.toDb()
          },
        },
        now: now,
      );
      await _insertAction(txn, action, now);
      return AgentMutation(value: saved, action: action);
    });
  }

  Future<AgentMutation<ReadingDifficulty>> updateDifficultyStatus(
    ReadingDifficulty difficulty, {
    required String sessionId,
    bool includeType = false,
  }) =>
      _dao.write((txn) async {
        final before = await _queryOne(
            txn, 'tb_reading_difficulties', 'id = ?', [difficulty.id]);
        if (before == null || before['book_id'] != difficulty.bookId) {
          throw StateError('Difficulty is unavailable for this book');
        }
        final saved = ReadingDifficulty.fromDb(before).copyWith(
          status: difficulty.status,
          type: includeType ? difficulty.type : null,
          updatedAt: difficulty.updatedAt,
        );
        await txn.update('tb_reading_difficulties', saved.toDb(),
            where: 'id = ?', whereArgs: [difficulty.id]);
        final action = _action(
          type: AgentActionType.difficulty,
          targetId: difficulty.id,
          bookId: difficulty.bookId,
          sessionId: sessionId,
          before: before,
          after: saved.toDb(),
          now: _clock(),
        );
        await _insertAction(txn, action, _clock());
        return AgentMutation(value: saved, action: action);
      });

  Future<UndoResult> undo(String actionId) async {
    final now = _clock();
    return _dao.write((txn) async {
      final row =
          await _queryOne(txn, 'tb_agent_actions', 'id = ?', [actionId]);
      if (row == null) return UndoResult.missing;
      final action = AgentAction.fromDb(row);
      if (action.status == AgentActionStatus.undone) {
        return UndoResult.alreadyUndone;
      }
      if (now > action.expiresAt) return UndoResult.expired;
      final current = await _currentSnapshot(txn, action);
      if (_hash(current) != action.afterHash) {
        await txn.update(
          'tb_agent_actions',
          {'status': AgentActionStatus.conflict.name},
          where: 'id = ?',
          whereArgs: [action.id],
        );
        return UndoResult.conflict;
      }
      await _restore(txn, action, 'agent-action-${action.sessionId}');
      await txn.update(
        'tb_agent_actions',
        {'status': AgentActionStatus.undone.name, 'undone_at': now},
        where: 'id = ?',
        whereArgs: [action.id],
      );
      return UndoResult.undone;
    });
  }

  void _validateGoal(ReadingGoal goal) {
    if (goal.id.isEmpty || goal.bookId <= 0 || goal.title.trim().isEmpty) {
      throw ArgumentError('Goal requires id, book, and title');
    }
    if (goal.criteria.length > 3) {
      throw ArgumentError('A reading goal supports at most three criteria');
    }
    if (goal.progress < 0 || goal.progress > 1) {
      throw ArgumentError.value(goal.progress, 'progress');
    }
    if (goal.timeBudgetMinutes != null && goal.timeBudgetMinutes! <= 0) {
      throw ArgumentError.value(goal.timeBudgetMinutes, 'timeBudgetMinutes');
    }
  }

  void _validateProfileKey(String key) {
    if (!supportedReaderProfileKeys.contains(key)) {
      throw ArgumentError.value(key, 'key', 'Unsupported reader preference');
    }
  }

  AgentAction _action({
    required AgentActionType type,
    required String targetId,
    int? bookId,
    required String sessionId,
    required Map<String, dynamic>? before,
    required Map<String, dynamic>? after,
    required int now,
  }) =>
      AgentAction(
        id: _uuid.v4(),
        type: type,
        targetId: targetId,
        bookId: bookId,
        beforeSnapshot: before,
        afterSnapshot: after,
        afterHash: _hash(after),
        sessionId: sessionId,
        createdAt: now,
        expiresAt: now + retention.inMilliseconds,
      );

  Future<void> _insertAction(
      Transaction txn, AgentAction action, int now) async {
    await txn.insert('tb_agent_actions', action.toDb());
    await txn
        .delete('tb_agent_actions', where: 'expires_at < ?', whereArgs: [now]);
    await txn.rawDelete('''DELETE FROM tb_agent_actions WHERE id IN (
      SELECT id FROM tb_agent_actions ORDER BY created_at DESC LIMIT -1 OFFSET ?
    )''', [maxActions]);
  }

  Future<Map<String, dynamic>?> _currentSnapshot(
      Transaction txn, AgentAction action) async {
    switch (action.type) {
      case AgentActionType.goal:
        return _queryOne(txn, 'tb_reading_goals', 'id = ?', [action.targetId]);
      case AgentActionType.profile:
        return _queryOne(txn, 'tb_reader_profile_items', 'profile_key = ?',
            [action.targetId]);
      case AgentActionType.note:
        final value = await _noteSnapshot(txn, action.targetId);
        final owned = action.afterSnapshot?['ownedAnnotationId'];
        if (value != null && owned != null) value['ownedAnnotationId'] = owned;
        return value;
      case AgentActionType.difficulty:
        final value = await _queryOne(
            txn, 'tb_reading_difficulties', 'id = ?', [action.targetId]);
        if (value != null &&
            action.afterSnapshot?.containsKey('_sourceAnchor') == true) {
          final anchor = action.afterSnapshot!['_sourceAnchor'] as Map;
          value['_sourceAnchor'] = await _queryOne(
              txn, 'tb_reading_artifacts', 'id = ?', [anchor['id']]);
          value['_difficultyExisted'] = true;
        }
        return value;
      case AgentActionType.memory:
        final closure = action.afterSnapshot?['chapterClosure'];
        if (closure is Map) {
          return _chapterClosureSnapshot(
              txn, Map<String, dynamic>.from(closure));
        }
        final memoryBook = action.afterSnapshot?['practiceMemoryBook'];
        if (memoryBook is int) return _memoryBookSnapshot(txn, memoryBook);
        final practice = action.afterSnapshot?['practice'];
        if (practice is String) {
          return _practiceSnapshot(
              txn,
              ReadingPracticeRecordKind.values.byName(practice),
              action.targetId,
              reviewId: action.afterSnapshot?['reviewId'] as String?);
        }
        if (action.afterSnapshot?['knowledgeCard'] is Map) {
          final card = await _queryOne(
              txn, 'tb_knowledge_cards', 'id = ?', [action.targetId]);
          return card == null ? null : {'knowledgeCard': card};
        }
        return _queryOne(
            txn, 'tb_reading_memory_documents', 'id = ?', [action.targetId]);
      case AgentActionType.artifact:
        return _queryOne(
            txn, 'tb_reading_artifacts', 'id = ?', [action.targetId]);
      case AgentActionType.wiki:
        return _wikiSnapshot(txn, action.targetId);
    }
  }

  Future<void> _expandArtifactCoverage(
    Transaction txn,
    ReadingArtifact artifact,
  ) async {
    final rows = await txn.query(
      'tb_book_reading_coverage',
      where: 'book_id = ?',
      whereArgs: [artifact.bookId],
      limit: 1,
    );
    if (rows.isEmpty) return;
    final coverage = BookReadingCoverage.fromDb(rows.first);
    await txn.update(
      'tb_book_reading_coverage',
      {
        'artifact_coverage_start':
            artifact.sourceProgress < coverage.artifactCoverageStart
                ? artifact.sourceProgress
                : coverage.artifactCoverageStart,
        'artifact_coverage_end':
            artifact.sourceProgress > coverage.artifactCoverageEnd
                ? artifact.sourceProgress
                : coverage.artifactCoverageEnd,
        'updated_at': _clock(),
      },
      where: 'book_id = ?',
      whereArgs: [artifact.bookId],
    );
  }

  Future<void> _restore(
      Transaction txn, AgentAction action, String syncDeviceId) async {
    switch (action.type) {
      case AgentActionType.goal:
        final snapshot = action.beforeSnapshot ?? const {};
        final target = snapshot['target'];
        await txn.delete('tb_reading_goals',
            where: 'id = ?', whereArgs: [action.targetId]);
        if (target == null && action.bookId != null) {
          await _recordSyncDeletion(
              txn, 'goal', action.targetId, action.bookId!, syncDeviceId);
        }
        if (target is Map) {
          await txn.insert(
              'tb_reading_goals', Map<String, Object?>.from(target));
        }
        final previous = snapshot['previousActive'];
        if (previous is Map && previous['id'] != action.targetId) {
          await txn.insert(
              'tb_reading_goals', Map<String, Object?>.from(previous),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return;
      case AgentActionType.profile:
        if (action.beforeSnapshot == null) {
          await txn.delete('tb_reader_profile_items',
              where: 'profile_key = ?', whereArgs: [action.targetId]);
        } else {
          await txn.insert('tb_reader_profile_items',
              Map<String, Object?>.from(action.beforeSnapshot!),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return;
      case AgentActionType.note:
        await _deleteDocument(txn, action.targetId);
        final owned = action.afterSnapshot?['ownedAnnotationId'];
        if (owned is int) {
          await txn.delete('tb_notes', where: 'id = ?', whereArgs: [owned]);
        }
        return;
      case AgentActionType.difficulty:
        final before = action.beforeSnapshot == null
            ? null
            : Map<String, dynamic>.from(action.beforeSnapshot!);
        final hasAnchor = before?.containsKey('_sourceAnchor') == true;
        final anchorBefore = before?.remove('_sourceAnchor');
        final existed = before?.remove('_difficultyExisted');
        if (hasAnchor) {
          final afterAnchor = action.afterSnapshot!['_sourceAnchor'] as Map;
          await txn.delete('tb_reading_artifacts',
              where: 'id = ?', whereArgs: [afterAnchor['id']]);
          if (anchorBefore is Map) {
            await txn.insert('tb_reading_artifacts',
                Map<String, Object?>.from(anchorBefore));
          } else if (action.bookId != null) {
            await _recordSyncDeletion(txn, 'artifact',
                afterAnchor['id'].toString(), action.bookId!, syncDeviceId);
          }
        }
        if (before == null || existed == false) {
          await txn.delete('tb_reading_difficulties',
              where: 'id = ?', whereArgs: [action.targetId]);
          if (action.bookId != null) {
            await _recordSyncDeletion(txn, 'difficulty', action.targetId,
                action.bookId!, syncDeviceId);
          }
        } else {
          await txn.insert(
              'tb_reading_difficulties', Map<String, Object?>.from(before),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return;
      case AgentActionType.memory:
        final closure = action.beforeSnapshot?['chapterClosure'];
        if (closure is Map) {
          final before = action.beforeSnapshot!;
          for (final entry in _closureTables.entries) {
            final id = closure[entry.key];
            if (id == null) continue;
            await txn.delete(entry.value, where: 'id = ?', whereArgs: [id]);
            final row = before[entry.key];
            if (row is Map) {
              await txn.insert(entry.value, Map<String, Object?>.from(row));
            } else if (action.bookId != null) {
              await _recordSyncDeletion(
                  txn,
                  entry.key == 'card' ? 'knowledgeCard' : entry.key,
                  id.toString(),
                  action.bookId!,
                  syncDeviceId);
            }
          }
          final ids = closure['anchors'] as List;
          final anchors = before['anchors'] as List;
          for (var index = 0; index < ids.length; index++) {
            await txn.delete('tb_reading_artifacts',
                where: 'id = ?', whereArgs: [ids[index]]);
            final row = anchors[index];
            if (row is Map) {
              await txn.insert(
                  'tb_reading_artifacts', Map<String, Object?>.from(row));
            } else if (action.bookId != null) {
              await _recordSyncDeletion(txn, 'artifact', ids[index].toString(),
                  action.bookId!, syncDeviceId);
            }
          }
          return;
        }
        final memoryBook = action.beforeSnapshot?['practiceMemoryBook'];
        if (memoryBook is int) {
          await _clearMemoryBook(txn, memoryBook);
          final rows = action.beforeSnapshot!['rows'] as Map;
          for (final table in rows.keys) {
            for (final row in rows[table] as List) {
              await txn.insert(
                  table.toString(), Map<String, Object?>.from(row as Map));
            }
          }
          return;
        }
        final practice = action.beforeSnapshot?['practice'];
        if (practice is String) {
          final kind = ReadingPracticeRecordKind.values.byName(practice);
          final before = action.beforeSnapshot!;
          await txn.delete(kind.table,
              where: '${kind.key} = ?', whereArgs: [action.targetId]);
          final row = before['row'];
          if (row is Map) {
            await txn.insert(kind.table, Map<String, Object?>.from(row));
          }
          final reviewId = before['reviewId'];
          if (reviewId != null) {
            await txn.delete('tb_reading_card_reviews',
                where: 'id = ?', whereArgs: [reviewId]);
            final review = before['review'];
            if (review is Map) {
              await txn.insert(
                  'tb_reading_card_reviews', Map<String, Object?>.from(review));
            }
          }
          if (kind == ReadingPracticeRecordKind.topic) {
            await txn.delete('tb_reading_note_sources',
                where: 'source_type = ? AND source_ref = ?',
                whereArgs: ['memoryTopic', action.targetId]);
            for (final source in before['noteSources'] as List? ?? const []) {
              await txn.insert('tb_reading_note_sources',
                  Map<String, Object?>.from(source as Map));
            }
          }
          if (kind == ReadingPracticeRecordKind.topic ||
              kind == ReadingPracticeRecordKind.card) {
            final (table, key) = kind == ReadingPracticeRecordKind.topic
                ? ('tb_reading_topic_sources', 'topic_id')
                : ('tb_reading_card_sources', 'card_id');
            await txn
                .delete(table, where: '$key = ?', whereArgs: [action.targetId]);
            for (final source in before['sourceIds'] as List? ?? const []) {
              await txn.insert(table, {
                key: action.targetId,
                ...Map<String, Object?>.from(source as Map)
              });
            }
          }
          return;
        }
        final card = action.beforeSnapshot?['knowledgeCard'];
        if (card is Map) {
          await txn.insert(
              'tb_knowledge_cards', Map<String, Object?>.from(card),
              conflictAlgorithm: ConflictAlgorithm.replace);
          return;
        }
        await txn.delete('tb_reading_memory_documents',
            where: 'id = ?', whereArgs: [action.targetId]);
        if (action.beforeSnapshot == null && action.bookId != null) {
          await _recordSyncDeletion(
              txn, 'memory', action.targetId, action.bookId!, syncDeviceId);
        }
        if (action.beforeSnapshot != null) {
          await txn.insert('tb_reading_memory_documents',
              Map<String, Object?>.from(action.beforeSnapshot!),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return;
      case AgentActionType.artifact:
        await txn.delete('tb_reading_artifacts',
            where: 'id = ?', whereArgs: [action.targetId]);
        if (action.beforeSnapshot == null && action.bookId != null) {
          await _recordSyncDeletion(
              txn, 'artifact', action.targetId, action.bookId!, syncDeviceId);
        }
        if (action.beforeSnapshot != null) {
          await txn.insert(
            'tb_reading_artifacts',
            Map<String, Object?>.from(action.beforeSnapshot!),
            conflictAlgorithm: ConflictAlgorithm.replace,
          );
        }
        if (action.bookId != null) {
          await _recomputeArtifactCoverage(txn, action.bookId!);
        }
        return;
      case AgentActionType.wiki:
        await txn.delete('tb_book_wiki_entry_sources',
            where: 'entry_id = ?', whereArgs: [action.targetId]);
        await txn.delete('tb_book_wiki_entries',
            where: 'id = ?', whereArgs: [action.targetId]);
        final snapshot = action.beforeSnapshot;
        final oldEntry = snapshot?['entry'];
        if (oldEntry is Map) {
          await txn.insert(
              'tb_book_wiki_entries', Map<String, Object?>.from(oldEntry),
              conflictAlgorithm: ConflictAlgorithm.replace);
          final oldSources = snapshot?['sources'];
          if (oldSources is List) {
            for (final source in oldSources.whereType<Map>()) {
              await txn.insert('tb_book_wiki_entry_sources',
                  Map<String, Object?>.from(source),
                  conflictAlgorithm: ConflictAlgorithm.replace);
            }
          }
        } else if (action.bookId != null) {
          await _recordSyncDeletion(
              txn, 'wikiEntry', action.targetId, action.bookId!, syncDeviceId);
        }
        return;
    }
  }

  Future<Map<String, dynamic>?> _wikiSnapshot(
      Transaction txn, String entryId) async {
    final entry =
        await _queryOne(txn, 'tb_book_wiki_entries', 'id = ?', [entryId]);
    if (entry == null) return null;
    final sources = await txn.query('tb_book_wiki_entry_sources',
        where: 'entry_id = ?',
        whereArgs: [entryId],
        orderBy: 'source_progress');
    return {'entry': entry, 'sources': sources};
  }

  Future<void> _recordSyncDeletion(Transaction txn, String entityType,
      String entityId, int bookId, String deviceId) async {
    final table = await txn.rawQuery(
      "SELECT name FROM sqlite_master WHERE type = 'table' "
      "AND name = 'tb_reading_sync_tombstones'",
    );
    if (table.isEmpty) return;
    await txn.insert(
      'tb_reading_sync_tombstones',
      {
        'entity_type': entityType,
        'entity_id': entityId,
        'book_id': bookId,
        'device_id': deviceId,
        'deleted_at': _clock(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<void> _insertDocument(
      Transaction txn, ReadingNoteDocument document) async {
    await txn.insert('tb_reading_notes', document.note.toDb());
    for (final block in document.blocks) {
      await txn.insert('tb_reading_note_blocks', block.toDb());
    }
    for (final source in document.sources) {
      await txn.insert('tb_reading_note_sources', source.toDb());
    }
    for (final tag in document.tags) {
      await txn.insert('tb_reading_tags', tag.toDb(),
          conflictAlgorithm: ConflictAlgorithm.ignore);
      await txn.insert('tb_reading_note_tags',
          {'note_id': document.note.id, 'tag_id': tag.id});
    }
  }

  Future<void> _recomputeArtifactCoverage(Transaction txn, int bookId) async {
    final coverageRows = await txn.query(
      'tb_book_reading_coverage',
      where: 'book_id = ?',
      whereArgs: [bookId],
      limit: 1,
    );
    if (coverageRows.isEmpty) return;
    final coverage = BookReadingCoverage.fromDb(coverageRows.first);
    final ranges = await txn.rawQuery(
      'SELECT MIN(source_progress) AS min_progress, '
      'MAX(source_progress) AS max_progress FROM tb_reading_artifacts '
      "WHERE book_id = ? AND status != 'retracted'",
      [bookId],
    );
    final min = ranges.first['min_progress'];
    final max = ranges.first['max_progress'];
    await txn.update(
      'tb_book_reading_coverage',
      {
        'artifact_coverage_start':
            min is num ? min.toDouble() : coverage.initializedAtProgress,
        'artifact_coverage_end':
            max is num ? max.toDouble() : coverage.initializedAtProgress,
        'updated_at': _clock(),
      },
      where: 'book_id = ?',
      whereArgs: [bookId],
    );
  }

  Future<Map<String, dynamic>?> _noteSnapshot(
      Transaction txn, String noteId) async {
    final note = await _queryOne(txn, 'tb_reading_notes', 'id = ?', [noteId]);
    if (note == null) return null;
    final blocks = await txn.query('tb_reading_note_blocks',
        where: 'note_id = ?', whereArgs: [noteId], orderBy: 'sort_order, id');
    final sources = await txn.query('tb_reading_note_sources',
        where: 'note_id = ?',
        whereArgs: [noteId],
        orderBy: 'source_type, source_ref');
    final tags = await txn.rawQuery('''SELECT t.* FROM tb_reading_tags t
      JOIN tb_reading_note_tags nt ON nt.tag_id = t.id
      WHERE nt.note_id = ? ORDER BY t.id''', [noteId]);
    return {
      'note': note,
      'blocks': blocks,
      'sources': sources,
      'tags': tags,
    };
  }

  Future<void> _deleteDocument(Transaction txn, String noteId) async {
    for (final table in [
      'tb_reading_note_tags',
      'tb_reading_note_revisions',
      'tb_reading_note_sources',
      'tb_reading_note_blocks',
    ]) {
      await txn.delete(table, where: 'note_id = ?', whereArgs: [noteId]);
    }
    await txn.delete('tb_reading_notes', where: 'id = ?', whereArgs: [noteId]);
  }
}

Future<Map<String, dynamic>?> _queryOne(Transaction txn, String table,
    String where, List<Object?> whereArgs) async {
  final rows =
      await txn.query(table, where: where, whereArgs: whereArgs, limit: 1);
  return rows.isEmpty ? null : Map<String, dynamic>.from(rows.first);
}

String _hash(Object? value) =>
    sha256.convert(utf8.encode(jsonEncode(_canonical(value)))).toString();

Object? _canonical(Object? value) {
  if (value is Map) {
    final keys = value.keys.map((key) => key.toString()).toList()..sort();
    return {for (final key in keys) key: _canonical(value[key])};
  }
  if (value is List) return value.map(_canonical).toList(growable: false);
  return value;
}

final readingAgentRepository = ReadingAgentRepository();
