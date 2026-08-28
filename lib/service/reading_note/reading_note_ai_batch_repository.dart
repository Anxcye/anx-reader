import 'dart:convert';

import 'package:anx_reader/dao/reading_memory.dart';
import 'package:anx_reader/dao/reading_note.dart';
import 'package:anx_reader/dao/reading_note_ai.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/models/reading_note_ai.dart';
import 'package:anx_reader/service/reading_note/reading_note_ai_organizer_service.dart';
import 'package:anx_reader/service/reading_note/reading_note_repository.dart';
import 'package:crypto/crypto.dart';
import 'package:sqflite/sqflite.dart';
import 'package:uuid/uuid.dart';

class ReadingNoteAiPreparedBatch {
  const ReadingNoteAiPreparedBatch({
    required this.batch,
    required this.inputs,
    required this.remaining,
  });
  final ReadingNoteAiBatch batch;
  final List<ReadingNoteAiInput> inputs;
  final List<ReadingNoteListItem> remaining;
}

class ReadingNoteAiBatchRepository {
  ReadingNoteAiBatchRepository({
    ReadingNoteAiDao? aiDao,
    ReadingNoteDao? noteDao,
    ReadingMemoryDao? memoryDao,
    ReadingNoteRepository? notes,
    Uuid? uuid,
  })  : _aiDao = aiDao ?? readingNoteAiDao,
        _noteDao = noteDao ?? readingNoteDaoInstance,
        _memoryDao = memoryDao ?? readingMemoryDao,
        _notes = notes ?? ReadingNoteRepository(),
        _uuid = uuid ?? const Uuid();

  static const maxBatchSize = 30;
  final ReadingNoteAiDao _aiDao;
  final ReadingNoteDao _noteDao;
  final ReadingMemoryDao _memoryDao;
  final ReadingNoteRepository _notes;
  final Uuid _uuid;

  Future<List<ReadingNoteAiBatch>> batches(int bookId) =>
      _aiDao.batches(bookId);
  Future<List<ReadingNoteAiSuggestion>> suggestions(String batchId) =>
      _aiDao.suggestions(batchId);
  Future<void> deleteBookOrganizerData(int bookId) =>
      _aiDao.deleteBookOrganizerData(bookId);
  Future<List<ReadingMemoryTopic>> keptTopics(int bookId) async =>
      (await _memoryDao.topics(bookId))
          .where((topic) => topic.status == ReadingMemoryItemStatus.kept)
          .toList(growable: false);

  Future<ReadingNoteAiPreparedBatch> prepare({
    required Book book,
    required ReadingNoteAiScope scope,
    required List<ReadingNoteListItem> items,
  }) async {
    final scoped = items.where((item) => item.book.id == book.id).toList();
    final current = scoped.take(maxBatchSize).toList(growable: false);
    final remaining = scoped.skip(maxBatchSize).toList(growable: false);
    final inputs = current.map(_input).toList(growable: false);
    final now = DateTime.now().millisecondsSinceEpoch;
    final batch = ReadingNoteAiBatch(
      id: _uuid.v4(),
      bookId: book.id,
      scope: scope,
      sourceSnapshot: scoped.map((item) => item.identity).toList(),
      status: ReadingNoteAiBatchStatus.pending,
      totalCount: scoped.length,
      remainingCount: remaining.length,
      createdAt: now,
      updatedAt: now,
    );
    await _aiDao.archivePendingSources(
      book.id,
      inputs.map((item) => (item.sourceType, item.sourceRef)).toList(),
    );
    await _aiDao.saveBatch(batch);
    return ReadingNoteAiPreparedBatch(
        batch: batch, inputs: inputs, remaining: remaining);
  }

  Future<List<ReadingNoteAiInput>> inputsForBatch(
    ReadingNoteAiBatch batch, {
    required List<ReadingNoteListItem> items,
  }) async {
    final byIdentity = {for (final item in items) item.identity: item};
    return batch.sourceSnapshot
        .take(maxBatchSize)
        .map((identity) => byIdentity[identity])
        .whereType<ReadingNoteListItem>()
        .map(_input)
        .toList(growable: false);
  }

  Future<ReadingNoteAiPreparedBatch?> prepareNext({
    required Book book,
    required ReadingNoteAiBatch previous,
    required List<ReadingNoteListItem> items,
  }) async {
    final byIdentity = {for (final item in items) item.identity: item};
    final processed = previous.totalCount - previous.remainingCount;
    final remaining = previous.sourceSnapshot
        .skip(processed)
        .map((identity) => byIdentity[identity])
        .whereType<ReadingNoteListItem>()
        .toList(growable: false);
    if (remaining.isEmpty) return null;
    return prepare(book: book, scope: previous.scope, items: remaining);
  }

  ReadingNoteAiInput _input(ReadingNoteListItem item) {
    final sourceType = item.isLegacy
        ? ReadingNoteAiSourceType.annotation
        : ReadingNoteAiSourceType.readingNote;
    final sourceRef = item.isLegacy
        ? item.legacyAnnotation!.id.toString()
        : item.document!.note.id;
    final tags =
        item.document?.tags.map((tag) => tag.name).toList() ?? const [];
    final hash = contentHash(item);
    return ReadingNoteAiInput(
      sourceId: '${sourceType.name}:$sourceRef',
      sourceType: sourceType,
      sourceRef: sourceRef,
      title: item.title,
      quote: item.quote,
      body: item.body,
      tags: tags,
      chapter: item.chapter,
      contentHash: hash,
    );
  }

  String contentHash(ReadingNoteListItem item) => _hash(jsonEncode({
        'title': item.title,
        'quote': item.quote,
        'body': item.body,
        'tags':
            (item.document?.tags.map((tag) => tag.normalizedName).toList() ??
                <String>[])
              ..sort(),
      }));

  Future<void> markRunning(ReadingNoteAiBatch batch) => _aiDao.updateBatch(
        batch.copyWith(
          status: ReadingNoteAiBatchStatus.running,
          clearError: true,
          updatedAt: DateTime.now().millisecondsSinceEpoch,
        ),
      );

  Future<void> saveGenerated({
    required ReadingNoteAiBatch batch,
    required List<ReadingNoteAiInput> inputs,
    required List<ReadingNoteAiParsedSuggestion> parsed,
    required String? providerId,
    required String? model,
    required bool usedFallback,
  }) async {
    final inputMap = {for (final item in inputs) item.sourceId: item};
    final now = DateTime.now().millisecondsSinceEpoch;
    final suggestions = parsed.map((item) {
      final input = inputMap[item.sourceId]!;
      final fields = <ReadingNoteAiAdoptableField>{
        if (item.title.isNotEmpty) ReadingNoteAiAdoptableField.title,
        if (item.body.isNotEmpty) ReadingNoteAiAdoptableField.aiBlock,
        if (item.tags.isNotEmpty) ReadingNoteAiAdoptableField.tags,
        if (item.existingTopicIds.isNotEmpty || item.newTopics.isNotEmpty)
          ReadingNoteAiAdoptableField.topics,
      };
      return ReadingNoteAiSuggestion(
        id: _uuid.v4(),
        batchId: batch.id,
        bookId: batch.bookId,
        sourceType: input.sourceType,
        sourceRef: input.sourceRef,
        contentHash: input.contentHash,
        suggestedTitle: item.title,
        suggestedBody: item.body,
        suggestedTags: item.tags,
        existingTopicIds: item.existingTopicIds,
        newTopics: item.newTopics,
        selectedFields: fields,
        status: ReadingNoteAiSuggestionStatus.pending,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
    await _aiDao.saveSuggestions(suggestions);
    await _aiDao.updateBatch(batch.copyWith(
      status: ReadingNoteAiBatchStatus.reviewing,
      providerId: providerId,
      model: model,
      usedFallback: usedFallback,
      updatedAt: now,
    ));
  }

  Future<void> markFailed(ReadingNoteAiBatch batch, Object error) async {
    final current = await _aiDao.batch(batch.id);
    if (current?.status == ReadingNoteAiBatchStatus.abandoned) return;
    await _aiDao.updateBatch((current ?? batch).copyWith(
      status: ReadingNoteAiBatchStatus.failed,
      error: error.toString(),
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> updateSelection(ReadingNoteAiSuggestion item,
          Set<ReadingNoteAiAdoptableField> fields) =>
      _aiDao.updateSuggestion(item.copyWith(
          selectedFields: fields,
          updatedAt: DateTime.now().millisecondsSinceEpoch));

  Future<ReadingNoteDocument?> apply(
    ReadingNoteAiSuggestion suggestion, {
    required String? providerId,
    required String? model,
    required bool usedFallback,
  }) async {
    if (suggestion.selectedFields.isEmpty) {
      await ignore(suggestion);
      return null;
    }
    var document = await _resolveDocument(suggestion);
    if (document == null) return null;
    final item =
        ReadingNoteListItem(document: document, book: await _book(document));
    if (contentHash(item) != suggestion.contentHash) {
      throw StateError('The note changed after AI organization');
    }
    final before = _snapshot(document);
    final fields = suggestion.selectedFields;
    final mergedTags = fields.contains(ReadingNoteAiAdoptableField.tags)
        ? {...document.tags.map((tag) => tag.name), ...suggestion.suggestedTags}
            .toList()
        : document.tags.map((tag) => tag.name).toList();
    final now = DateTime.now().millisecondsSinceEpoch;
    final updatedNote = document.note.copyWith(
      title: fields.contains(ReadingNoteAiAdoptableField.title)
          ? suggestion.suggestedTitle.trim()
          : document.note.title,
      updatedAt: now,
    );
    final textBlock = document.blocks
        .firstWhere((block) => block.type == ReadingNoteBlockType.text);
    final tags = mergedTags
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .map((name) => ReadingNoteTag(
              id: 'tag-${_uuid.v5(Namespace.url.value, name.toLowerCase())}',
              name: name,
              normalizedName: name.toLowerCase(),
              createdAt: now,
              updatedAt: now,
            ))
        .toList(growable: false);
    final aiBlock = fields.contains(ReadingNoteAiAdoptableField.aiBlock)
        ? ReadingNoteBlock(
            id: _uuid.v4(),
            noteId: updatedNote.id,
            type: ReadingNoteBlockType.ai,
            content: suggestion.suggestedBody,
            sortOrder: document.blocks.length,
            origin: ReadingNoteBlockOrigin.ai,
            createdAt: now,
            updatedAt: now,
            metadata: {
              'batchId': suggestion.batchId,
              'suggestionId': suggestion.id,
              'providerId': providerId,
              'model': model,
              'usedFallback': usedFallback,
              'generatedAt': now,
            },
          )
        : null;
    final topicEffects = fields.contains(ReadingNoteAiAdoptableField.topics)
        ? await _topicEffects(document, suggestion, now)
        : null;
    final expected = ReadingNoteDocument(
      note: updatedNote,
      blocks: [...document.blocks, if (aiBlock != null) aiBlock],
      sources: [
        ...document.sources,
        ...?topicEffects?.noteSources,
      ],
      tags: tags,
    );
    final adopted = suggestion.copyWith(
      status: ReadingNoteAiSuggestionStatus.adopted,
      beforeSnapshot: before,
      appliedHash: _documentHash(expected),
      updatedAt: now,
    );
    final annotationId = document.sources
        .where((source) => source.type == ReadingNoteSourceType.annotation)
        .map((source) => int.tryParse(source.sourceRef))
        .whereType<int>()
        .firstOrNull;
    final database = await _aiDao.database;
    await database.transaction((txn) async {
      await txn.update('tb_reading_notes', updatedNote.toDb(),
          where: 'id = ?', whereArgs: [updatedNote.id]);
      await txn.delete('tb_reading_note_tags',
          where: 'note_id = ?', whereArgs: [updatedNote.id]);
      for (final tag in tags) {
        await txn.insert('tb_reading_tags', tag.toDb(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
        await txn.insert('tb_reading_note_tags',
            {'note_id': updatedNote.id, 'tag_id': tag.id},
            conflictAlgorithm: ConflictAlgorithm.ignore);
      }
      await txn.insert(
          'tb_reading_note_revisions',
          ReadingNoteRevision(
            id: _uuid.v4(),
            noteId: updatedNote.id,
            title: updatedNote.title,
            body: textBlock.content,
            tags: tags.map((tag) => tag.name).toList(),
            status: updatedNote.status,
            createdAt: now,
          ).toDb());
      if (aiBlock != null) {
        await txn.insert('tb_reading_note_blocks', aiBlock.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace);
      }
      if (annotationId != null) {
        await txn.update(
            'tb_notes',
            {
              'reader_note': textBlock.content,
              'update_time':
                  DateTime.fromMillisecondsSinceEpoch(now).toIso8601String(),
            },
            where: 'id = ?',
            whereArgs: [annotationId]);
      }
      if (topicEffects != null) {
        await txn.insert(
            'tb_reading_memory_sources', topicEffects.memorySource.toDb(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
        for (final topic in topicEffects.newTopics) {
          await txn.insert('tb_reading_memory_topics', topic.toDb(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
          await txn.insert('tb_reading_topic_sources',
              {'topic_id': topic.id, 'source_id': topicEffects.memorySource.id},
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        for (final source in topicEffects.noteSources) {
          await txn.insert('tb_reading_note_sources', source.toDb(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      }
      await txn.update('tb_reading_note_ai_suggestions', adopted.toDb(),
          where: 'id = ?', whereArgs: [adopted.id]);
    });
    final applied = await _notes.document(updatedNote);
    await _completeBatchIfDone(suggestion.batchId);
    return applied;
  }

  Future<Book> _book(ReadingNoteDocument document) async =>
      (await _notes.books())
          .firstWhere((book) => book.id == document.note.bookId);

  Future<ReadingNoteDocument?> _resolveDocument(
      ReadingNoteAiSuggestion suggestion) async {
    if (suggestion.sourceType == ReadingNoteAiSourceType.readingNote) {
      final note = await _noteDao.note(suggestion.sourceRef);
      return note == null ? null : _notes.document(note);
    }
    final items =
        await _notes.list(ReadingNoteQuery(bookId: suggestion.bookId));
    final item = items
        .where((item) =>
            item.isLegacy &&
            item.legacyAnnotation?.id.toString() == suggestion.sourceRef)
        .firstOrNull;
    return item == null ? null : _notes.mapLegacy(item.legacyAnnotation!);
  }

  Future<_TopicEffects> _topicEffects(ReadingNoteDocument document,
      ReadingNoteAiSuggestion suggestion, int now) async {
    final source = await _memorySource(document, now);
    final topics = <ReadingMemoryTopic>[];
    for (final item in suggestion.newTopics) {
      final id =
          'topic-note-ai-${_hash('${suggestion.batchId}|${item['title']}')}';
      topics.add(ReadingMemoryTopic(
        id: id,
        bookId: document.note.bookId,
        title: item['title'].toString(),
        summary: item['summary'].toString(),
        status: ReadingMemoryItemStatus.suggested,
        batchId: suggestion.batchId,
        sourceIds: [source.id],
        createdAt: now,
        updatedAt: now,
      ));
    }
    return _TopicEffects(
      memorySource: source,
      newTopics: topics,
      noteSources: [
        for (final topicId in suggestion.existingTopicIds)
          ReadingNoteSource(
            noteId: document.note.id,
            type: ReadingNoteSourceType.memoryTopic,
            sourceRef: topicId,
            chapterTitle: document.sources.firstOrNull?.chapterTitle,
            chapterHref: document.sources.firstOrNull?.chapterHref,
            cfi: document.sources.firstOrNull?.cfi,
            textSnapshot: document.quote,
            createdAt: now,
          ),
      ],
    );
  }

  Future<ReadingMemorySource> _memorySource(
      ReadingNoteDocument document, int now) async {
    final text = [document.quote, document.body]
        .where((value) => value.trim().isNotEmpty)
        .join('\n');
    final snapshot = text.length > 240 ? text.substring(0, 240) : text;
    final hash = _hash(
        '${document.note.bookId}|readingNote|${document.note.id}|$snapshot');
    return ReadingMemorySource(
      id: 'source-$hash',
      bookId: document.note.bookId,
      type: ReadingMemorySourceType.readingNote,
      sourceRef: document.note.id,
      chapterHref: document.sources.firstOrNull?.chapterHref,
      chapterTitle: document.sources.firstOrNull?.chapterTitle,
      cfi: document.sources.firstOrNull?.cfi,
      text: snapshot,
      contentHash: hash,
      createdAt: now,
    );
  }

  Future<void> ignore(ReadingNoteAiSuggestion suggestion) async {
    await _aiDao.updateSuggestion(suggestion.copyWith(
      status: ReadingNoteAiSuggestionStatus.ignored,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
    await _completeBatchIfDone(suggestion.batchId);
  }

  Future<void> undo(ReadingNoteAiSuggestion suggestion) async {
    if (suggestion.status != ReadingNoteAiSuggestionStatus.adopted ||
        suggestion.beforeSnapshot == null) {
      return;
    }
    final noteId = suggestion.sourceType == ReadingNoteAiSourceType.readingNote
        ? suggestion.sourceRef
        : await _noteDao.mappedAnnotationId(int.parse(suggestion.sourceRef));
    final note = noteId == null ? null : await _noteDao.note(noteId);
    if (note == null) throw StateError('Note no longer exists');
    final current = await _notes.document(note);
    if (_documentHash(current) != suggestion.appliedHash) {
      throw StateError('The note changed after adoption');
    }
    final snapshot = suggestion.beforeSnapshot!;
    final aiBlocks = current.blocks.where((block) =>
        block.type == ReadingNoteBlockType.ai &&
        block.metadata['suggestionId'] == suggestion.id);
    for (final block in aiBlocks) {
      await _noteDao.deleteBlock(block.id);
    }
    await _removeTopicEffects(current.note.id, suggestion);
    await _notes.save(
      currentDocument: current,
      title: snapshot['title']?.toString() ?? '',
      body: snapshot['body']?.toString() ?? '',
      status: ReadingNoteStatus.values.byName(snapshot['status'].toString()),
      favorite: snapshot['favorite'] == true,
      tagNames: (snapshot['tags'] as List? ?? const [])
          .map((e) => e.toString())
          .toList(),
      recordRevision: true,
    );
    await _aiDao.updateSuggestion(suggestion.copyWith(
      status: ReadingNoteAiSuggestionStatus.pending,
      selectedFields: suggestion.selectedFields,
      updatedAt: DateTime.now().millisecondsSinceEpoch,
    ));
  }

  Future<void> undoBatch(String batchId) async {
    final adopted = (await suggestions(batchId))
        .where((item) => item.status == ReadingNoteAiSuggestionStatus.adopted)
        .toList()
        .reversed;
    for (final suggestion in adopted) {
      await undo(suggestion);
    }
  }

  Future<void> _removeTopicEffects(
      String noteId, ReadingNoteAiSuggestion suggestion) async {
    final database = await _aiDao.database;
    final newTopicIds = suggestion.newTopics
        .map((item) =>
            'topic-note-ai-${_hash('${suggestion.batchId}|${item['title']}')}')
        .toList(growable: false);
    await database.transaction((txn) async {
      final originalTopicIds =
          (suggestion.beforeSnapshot?['topicIds'] as List? ?? const [])
              .map((item) => item.toString())
              .toSet();
      for (final topicId in [...suggestion.existingTopicIds, ...newTopicIds]) {
        if (originalTopicIds.contains(topicId)) continue;
        await txn.delete('tb_reading_note_sources',
            where: 'note_id = ? AND source_type = ? AND source_ref = ?',
            whereArgs: [
              noteId,
              ReadingNoteSourceType.memoryTopic.name,
              topicId
            ]);
      }
      for (final topicId in newTopicIds) {
        final rows = await txn.query('tb_reading_memory_topics',
            columns: ['status'], where: 'id = ?', whereArgs: [topicId]);
        if (rows.isEmpty ||
            rows.first['status'] != ReadingMemoryItemStatus.suggested.name) {
          continue;
        }
        await txn.delete('tb_reading_topic_sources',
            where: 'topic_id = ?', whereArgs: [topicId]);
        await txn.delete('tb_reading_memory_topics',
            where: 'id = ?', whereArgs: [topicId]);
      }
    });
  }

  Future<void> abandon(ReadingNoteAiBatch batch) =>
      _aiDao.updateBatch(batch.copyWith(
          status: ReadingNoteAiBatchStatus.abandoned,
          updatedAt: DateTime.now().millisecondsSinceEpoch));
  Future<void> clear(ReadingNoteAiBatch batch) =>
      _aiDao.clearPendingPayload(batch.id);

  Future<void> _completeBatchIfDone(String batchId) async {
    final items = await suggestions(batchId);
    if (items
        .any((item) => item.status == ReadingNoteAiSuggestionStatus.pending)) {
      return;
    }
    final batch = await _aiDao.batch(batchId);
    if (batch != null) {
      await _aiDao.updateBatch(batch.copyWith(
        status: ReadingNoteAiBatchStatus.completed,
        updatedAt: DateTime.now().millisecondsSinceEpoch,
      ));
    }
  }

  Map<String, dynamic> _snapshot(ReadingNoteDocument document) => {
        'title': document.note.title,
        'body': document.body,
        'tags': document.tags.map((tag) => tag.name).toList(),
        'status': document.note.status.name,
        'favorite': document.note.isFavorite,
        'topicIds': document.sources
            .where((source) => source.type == ReadingNoteSourceType.memoryTopic)
            .map((source) => source.sourceRef)
            .toList(),
      };

  String _documentHash(ReadingNoteDocument document) => _hash(jsonEncode({
        ..._snapshot(document),
        'ai': document.blocks
            .where((block) => block.type == ReadingNoteBlockType.ai)
            .map((block) => [block.id, block.content, block.metadata])
            .toList(),
      }));

  String _hash(String value) => sha256.convert(utf8.encode(value)).toString();
}

class _TopicEffects {
  const _TopicEffects({
    required this.memorySource,
    required this.newTopics,
    required this.noteSources,
  });
  final ReadingMemorySource memorySource;
  final List<ReadingMemoryTopic> newTopics;
  final List<ReadingNoteSource> noteSources;
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
