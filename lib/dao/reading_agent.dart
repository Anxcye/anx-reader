import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:sqflite/sqflite.dart';

class ReadingAgentDao extends BaseDao {
  ReadingAgentDao({super.databaseProvider});

  Future<BookReadingProfile?> bookReadingProfile(int bookId) => querySingle(
        'tb_book_reading_profiles',
        mapper: BookReadingProfile.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
      );

  Future<void> saveBookReadingProfile(BookReadingProfile profile) => insert(
        'tb_book_reading_profiles',
        profile.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<void> deleteBookReadingProfile(int bookId) => delete(
        'tb_book_reading_profiles',
        where: 'book_id = ?',
        whereArgs: [bookId],
      );

  Future<BookReadingCoverage?> bookReadingCoverage(int bookId) => querySingle(
        'tb_book_reading_coverage',
        mapper: BookReadingCoverage.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
      );

  Future<void> saveBookReadingCoverage(BookReadingCoverage coverage) => insert(
        'tb_book_reading_coverage',
        coverage.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );

  Future<ReadingGoal?> activeGoal(int bookId) => querySingle(
        'tb_reading_goals',
        mapper: ReadingGoal.fromDb,
        where: "book_id = ? AND status = 'active'",
        whereArgs: [bookId],
      );

  Future<ReadingGoal?> goal(String id) => querySingle(
        'tb_reading_goals',
        mapper: ReadingGoal.fromDb,
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<List<ReadingGoal>> goals(int bookId) => queryList(
        'tb_reading_goals',
        mapper: ReadingGoal.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'updated_at DESC',
      );

  Future<void> updateGoalProgress({
    required String id,
    required double progress,
    required int updatedAt,
  }) async {
    await update(
      'tb_reading_goals',
      {'progress': progress.clamp(0, 1), 'updated_at': updatedAt},
      where: "id = ? AND status = 'active'",
      whereArgs: [id],
    );
  }

  Future<ReaderProfileItem?> profileItem(String key) => querySingle(
        'tb_reader_profile_items',
        mapper: ReaderProfileItem.fromDb,
        where: 'profile_key = ?',
        whereArgs: [key],
      );

  Future<List<ReaderProfileItem>> profileItems({
    ReaderProfileStatus? status,
  }) =>
      queryList(
        'tb_reader_profile_items',
        mapper: ReaderProfileItem.fromDb,
        where: status == null ? null : 'status = ?',
        whereArgs: status == null ? null : [status.name],
        orderBy: 'updated_at DESC',
      );

  Future<AgentAction?> action(String id) => querySingle(
        'tb_agent_actions',
        mapper: AgentAction.fromDb,
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<List<AgentAction>> recentActions({
    int? bookId,
    int? createdAfter,
    int limit = 200,
  }) {
    final where = <String>[];
    final args = <Object?>[];
    if (bookId != null) {
      where.add('book_id = ?');
      args.add(bookId);
    }
    if (createdAfter != null) {
      where.add('created_at >= ?');
      args.add(createdAfter);
    }
    return queryList(
      'tb_agent_actions',
      mapper: AgentAction.fromDb,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: args.isEmpty ? null : args,
      orderBy: 'created_at DESC',
      limit: limit.clamp(1, 200),
    );
  }

  Future<List<ReadingChapterCheckpoint>> pendingCheckpoints(int bookId) =>
      queryList('tb_reading_checkpoints',
          mapper: ReadingChapterCheckpoint.fromDb,
          where: "book_id = ? AND status = 'pending'",
          whereArgs: [bookId],
          orderBy: 'updated_at DESC');

  Future<List<MasteryState>> masteryStates(int bookId) =>
      queryList('tb_reading_mastery',
          mapper: MasteryState.fromDb,
          where: 'book_id = ?',
          whereArgs: [bookId],
          orderBy: 'updated_at DESC');

  Future<
      List<
          KnowledgeCard>> dueKnowledgeCards(int bookId, int now) => queryList(
      'tb_knowledge_cards',
      mapper: KnowledgeCard.fromDb,
      where:
          "book_id = ? AND status = 'active' AND due_at IS NOT NULL AND due_at <= ?",
      whereArgs: [bookId, now],
      orderBy: 'due_at ASC');

  Future<List<KnowledgeCard>> knowledgeCards(int bookId) => queryList(
        'tb_knowledge_cards',
        mapper: KnowledgeCard.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'updated_at DESC',
      );

  Future<List<ReadingMemoryDocument>> memoryDocuments(int bookId) =>
      queryList('tb_reading_memory_documents',
          mapper: ReadingMemoryDocument.fromDb,
          where: 'book_id = ?',
          whereArgs: [bookId],
          orderBy: 'updated_at DESC');

  Future<List<ReadingArtifact>> artifacts(
    int bookId, {
    String? kind,
    ReadingArtifactStatus? status,
    double? visibleAtProgress,
  }) {
    final where = <String>['book_id = ?'];
    final args = <Object?>[bookId];
    if (kind != null) {
      where.add('artifact_kind = ?');
      args.add(kind);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.name);
    }
    if (visibleAtProgress != null) {
      where.add('visible_from_progress <= ?');
      args.add(visibleAtProgress.clamp(0, 1));
    }
    return queryList(
      'tb_reading_artifacts',
      mapper: ReadingArtifact.fromDb,
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );
  }

  Future<R> write<R>(Future<R> Function(Transaction txn) operation) =>
      transaction(operation);

  Future<BookWiki?> wiki(int bookId) => querySingle('tb_book_wikis',
      mapper: BookWiki.fromDb, where: 'book_id = ?', whereArgs: [bookId]);

  Future<List<BookWikiEntry>> wikiEntries(int bookId,
      {double? visibleAtProgress}) {
    final where = <String>['book_id = ?', "status = 'active'"];
    final args = <Object?>[bookId];
    if (visibleAtProgress != null) {
      where.add('visible_from_progress <= ?');
      args.add(visibleAtProgress);
    }
    return queryList('tb_book_wiki_entries',
        mapper: BookWikiEntry.fromDb,
        where: where.join(' AND '),
        whereArgs: args,
        orderBy: 'sort_key, updated_at');
  }

  Future<List<BookWikiSourceRef>> wikiSources(String entryId) =>
      queryList('tb_book_wiki_entry_sources',
          mapper: BookWikiSourceRef.fromDb,
          where: 'entry_id = ?',
          whereArgs: [entryId],
          orderBy: 'source_progress');
}

final readingAgentDao = ReadingAgentDao();
