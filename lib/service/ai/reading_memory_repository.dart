import 'dart:convert';

import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/dao/reading_coach.dart';
import 'package:anx_reader/dao/reading_memory.dart';
import 'package:anx_reader/dao/reading_note.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/service/ai/reading_review_scheduler.dart';
import 'package:crypto/crypto.dart';

class ReadingMemoryRepository {
  ReadingMemoryRepository({
    ReadingMemoryDao? dao,
    ReadingCoachDao? coachDao,
    BookNoteDao? noteDao,
    ReadingNoteDao? formalNoteDao,
  })  : _dao = dao ?? readingMemoryDao,
        _coachDao = coachDao ?? readingCoachDao,
        _noteDao = noteDao ?? bookNoteDao,
        _formalNoteDao = formalNoteDao ?? readingNoteDaoInstance;
  final ReadingMemoryDao _dao;
  final ReadingCoachDao _coachDao;
  final BookNoteDao _noteDao;
  final ReadingNoteDao _formalNoteDao;
  Future<List<ReadingMemorySource>> collectSources(int bookId,
      {bool includeUsed = false, bool includeAiBlocks = true}) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final candidates = <ReadingMemorySource>[];
    for (final item in await _coachDao.selectDifficulties(bookId)) {
      final text = item.text.trim();
      if (text.isEmpty) continue;
      candidates.add(_source(bookId, ReadingMemorySourceType.difficulty,
          item.id, item.chapterHref, item.chapterTitle, item.cfi, text, now));
    }
    for (final note in await _noteDao.selectBookNotesByBookId(bookId)) {
      final text = [note.content.trim(), note.readerNote?.trim() ?? '']
          .where((v) => v.isNotEmpty)
          .join('\n');
      if (text.isEmpty) continue;
      candidates.add(_source(bookId, ReadingMemorySourceType.annotation,
          note.id?.toString(), null, note.chapter, note.cfi, text, now));
    }
    for (final note in await _formalNoteDao.notes(bookId: bookId)) {
      final blocks = await _formalNoteDao.blocks(note.id);
      final text = blocks
          .where((block) =>
              includeAiBlocks || block.type != ReadingNoteBlockType.ai)
          .map((block) => block.content.trim())
          .where((value) => value.isNotEmpty)
          .join('\n');
      if (text.isEmpty) continue;
      final sources = await _formalNoteDao.sources(note.id);
      final source = sources.firstOrNull;
      candidates.add(_source(
          bookId,
          ReadingMemorySourceType.readingNote,
          note.id,
          source?.chapterHref,
          source?.chapterTitle,
          source?.cfi,
          text,
          now));
    }
    final deduped =
        {for (final item in candidates) item.contentHash: item}.values.toList();
    await _dao.saveSources(deduped);
    final used = includeUsed
        ? const <String>{}
        : (await _dao.usedSourceIds(bookId)).toSet();
    return deduped
        .where((item) => !used.contains(item.id))
        .take(80)
        .toList(growable: false);
  }

  ReadingMemorySource _source(
      int bookId,
      ReadingMemorySourceType type,
      String? ref,
      String? href,
      String? title,
      String? cfi,
      String text,
      int now) {
    final snapshot = text.length > 240 ? text.substring(0, 240) : text;
    final hash = sha256
        .convert(utf8.encode('$bookId|${type.name}|${cfi ?? ''}|$snapshot'))
        .toString();
    return ReadingMemorySource(
        id: 'source-$hash',
        bookId: bookId,
        type: type,
        sourceRef: ref,
        chapterHref: href,
        chapterTitle: title,
        cfi: cfi,
        text: snapshot,
        contentHash: hash,
        createdAt: now);
  }

  Future<List<ReadingMemorySource>> sources(int bookId) async {
    final stored = await _dao.sources(bookId);
    final difficulties = await _coachDao.selectDifficulties(bookId);
    final notes = await _noteDao.selectBookNotesByBookId(bookId);
    final formalNotes = await _formalNoteDao.notes(bookId: bookId);
    final difficultyIds = difficulties.map((item) => item.id).toSet();
    final noteIds = notes.map((item) => item.id?.toString()).nonNulls.toSet();
    final formalNoteIds = formalNotes.map((item) => item.id).toSet();
    return stored
        .map((source) => source.copyWith(
              isAvailable: switch (source.type) {
                ReadingMemorySourceType.difficulty =>
                  difficultyIds.contains(source.sourceRef),
                ReadingMemorySourceType.annotation =>
                  noteIds.contains(source.sourceRef),
                ReadingMemorySourceType.readingNote =>
                  formalNoteIds.contains(source.sourceRef),
              },
            ))
        .toList(growable: false);
  }

  Future<List<ReadingMemoryTopic>> topics(int bookId) => _dao.topics(bookId);
  Future<List<ReadingKnowledgeCard>> cards(int bookId) => _dao.cards(bookId);
  Future<List<ReadingCardReview>> reviews(int bookId) => _dao.reviews(bookId);
  Future<void> deleteBookMemory(int bookId) => _dao.deleteBookMemory(bookId);
  Future<void> saveTopics(List<ReadingMemoryTopic> items) =>
      _dao.saveTopics(items);
  Future<void> saveCards(List<ReadingKnowledgeCard> items) =>
      _dao.saveCards(items);
  Future<void> setTopicStatus(
      ReadingMemoryTopic item, ReadingMemoryItemStatus status) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    await _dao.updateTopic(item.copyWith(status: status, updatedAt: now));
    if (status != ReadingMemoryItemStatus.kept) return;
    final sourceMap = {
      for (final source in await _dao.sources(item.bookId)) source.id: source
    };
    for (final sourceId in item.sourceIds) {
      final source = sourceMap[sourceId];
      if (source?.type != ReadingMemorySourceType.readingNote ||
          source?.sourceRef == null) {
        continue;
      }
      final note = await _formalNoteDao.note(source!.sourceRef!);
      if (note == null) continue;
      await _formalNoteDao.saveSources([
        ReadingNoteSource(
          noteId: note.id,
          type: ReadingNoteSourceType.memoryTopic,
          sourceRef: item.id,
          chapterHref: source.chapterHref,
          chapterTitle: source.chapterTitle,
          cfi: source.cfi,
          textSnapshot: source.text,
          createdAt: now,
        ),
      ]);
    }
  }

  Future<void> setCardStatus(
          ReadingKnowledgeCard item, ReadingMemoryItemStatus status) =>
      _dao.updateCard(item.copyWith(
          status: status, updatedAt: DateTime.now().millisecondsSinceEpoch));
  Future<void> review(ReadingKnowledgeCard card, ReadingReviewRating rating,
      {int? now}) async {
    final time = now ?? DateTime.now().millisecondsSinceEpoch;
    final schedule = ReadingReviewScheduler.schedule(
        currentStage: card.reviewStage, rating: rating, now: time);
    final updated = card.copyWith(
        reviewStage: schedule.stage,
        nextReviewAt: schedule.nextReviewAt,
        hardCount:
            card.hardCount + (rating == ReadingReviewRating.hard ? 1 : 0),
        rememberedCount: card.rememberedCount +
            (rating == ReadingReviewRating.remembered ? 1 : 0),
        masteredCount: card.masteredCount +
            (rating == ReadingReviewRating.mastered ? 1 : 0),
        updatedAt: time);
    final record = ReadingCardReview(
        id: 'review-${card.id}-$time',
        cardId: card.id,
        bookId: card.bookId,
        rating: rating,
        previousStage: card.reviewStage,
        nextStage: schedule.stage,
        previousReviewAt: card.nextReviewAt,
        nextReviewAt: schedule.nextReviewAt,
        reviewedAt: time);
    await _dao.applyReview(updated, record);
  }

  Future<void> undoLatest(int bookId) async {
    final history = await reviews(bookId);
    if (history.isEmpty) return;
    final record = history.first;
    final card = (await cards(bookId))
        .where((item) => item.id == record.cardId)
        .firstOrNull;
    if (card == null) return;
    final restored = card.copyWith(
        reviewStage: record.previousStage,
        nextReviewAt: record.previousReviewAt,
        hardCount: (card.hardCount -
                (record.rating == ReadingReviewRating.hard ? 1 : 0))
            .clamp(0, card.hardCount),
        rememberedCount: (card.rememberedCount -
                (record.rating == ReadingReviewRating.remembered ? 1 : 0))
            .clamp(0, card.rememberedCount),
        masteredCount: (card.masteredCount -
                (record.rating == ReadingReviewRating.mastered ? 1 : 0))
            .clamp(0, card.masteredCount),
        updatedAt: DateTime.now().millisecondsSinceEpoch);
    await _dao.undoReview(restored, record);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
