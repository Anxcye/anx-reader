import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:sqflite/sqflite.dart';

class ReadingMemoryDao extends BaseDao {
  ReadingMemoryDao({super.databaseProvider});

  Future<void> saveSources(List<ReadingMemorySource> sources) =>
      transaction((txn) async {
        for (final source in sources) {
          await txn.insert('tb_reading_memory_sources', source.toDb(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });
  Future<List<ReadingMemorySource>> sources(int bookId) =>
      queryList('tb_reading_memory_sources',
          mapper: ReadingMemorySource.fromDb,
          where: 'book_id = ?',
          whereArgs: [bookId],
          orderBy: 'created_at DESC');
  Future<List<String>> usedSourceIds(int bookId) async => (await rawQueryList(
      '''SELECT DISTINCT ts.source_id AS id FROM tb_reading_topic_sources ts
       JOIN tb_reading_memory_topics t ON t.id = ts.topic_id
       WHERE t.book_id = ? AND t.status IN ('suggested','kept','ignored','active')''',
      arguments: [bookId], mapper: (row) => row['id'].toString()));

  Future<void> saveTopics(List<ReadingMemoryTopic> topics) =>
      transaction((txn) async {
        for (final topic in topics) {
          await txn.insert('tb_reading_memory_topics', topic.toDb(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
          for (final sourceId in topic.sourceIds) {
            await txn.insert('tb_reading_topic_sources',
                {'topic_id': topic.id, 'source_id': sourceId},
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      });
  Future<List<ReadingMemoryTopic>> topics(int bookId) async {
    final rows = await rawQueryList(
        'SELECT * FROM tb_reading_memory_topics WHERE book_id = ? ORDER BY updated_at DESC',
        arguments: [bookId],
        mapper: (row) => row);
    return Future.wait(rows.map((row) async => ReadingMemoryTopic.fromDb(
        row,
        await _relationIds(
            'tb_reading_topic_sources', 'topic_id', row['id'].toString()))));
  }

  Future<void> updateTopic(ReadingMemoryTopic topic) =>
      update('tb_reading_memory_topics', topic.toDb(),
          where: 'id = ?', whereArgs: [topic.id]);

  Future<void> saveCards(List<ReadingKnowledgeCard> cards) =>
      transaction((txn) async {
        for (final card in cards) {
          await txn.insert('tb_reading_knowledge_cards', card.toDb(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
          for (final sourceId in card.sourceIds) {
            await txn.insert('tb_reading_card_sources',
                {'card_id': card.id, 'source_id': sourceId},
                conflictAlgorithm: ConflictAlgorithm.ignore);
          }
        }
      });
  Future<List<ReadingKnowledgeCard>> cards(int bookId) async {
    final rows = await rawQueryList(
        'SELECT * FROM tb_reading_knowledge_cards WHERE book_id = ? ORDER BY updated_at DESC',
        arguments: [bookId],
        mapper: (row) => row);
    return Future.wait(rows.map((row) async => ReadingKnowledgeCard.fromDb(
        row,
        await _relationIds(
            'tb_reading_card_sources', 'card_id', row['id'].toString()))));
  }

  Future<void> updateCard(ReadingKnowledgeCard card) =>
      update('tb_reading_knowledge_cards', card.toDb(),
          where: 'id = ?', whereArgs: [card.id]);
  Future<List<ReadingCardReview>> reviews(int bookId) =>
      queryList('tb_reading_card_reviews',
          mapper: ReadingCardReview.fromDb,
          where: 'book_id = ?',
          whereArgs: [bookId],
          orderBy: 'reviewed_at DESC');

  Future<void> applyReview(
          ReadingKnowledgeCard card, ReadingCardReview review) =>
      transaction((txn) async {
        await txn.update('tb_reading_knowledge_cards', card.toDb(),
            where: 'id = ?', whereArgs: [card.id]);
        await txn.insert('tb_reading_card_reviews', review.toDb());
      });
  Future<void> undoReview(
          ReadingKnowledgeCard card, ReadingCardReview review) =>
      transaction((txn) async {
        await txn.update('tb_reading_knowledge_cards', card.toDb(),
            where: 'id = ?', whereArgs: [card.id]);
        await txn.delete('tb_reading_card_reviews',
            where: 'id = ?', whereArgs: [review.id]);
      });

  Future<void> deleteBookMemory(int bookId) => transaction((txn) async {
        final topicRows = await txn.query('tb_reading_memory_topics',
            columns: ['id'], where: 'book_id = ?', whereArgs: [bookId]);
        final cardRows = await txn.query('tb_reading_knowledge_cards',
            columns: ['id'], where: 'book_id = ?', whereArgs: [bookId]);

        for (final row in cardRows) {
          await txn.delete('tb_reading_card_sources',
              where: 'card_id = ?', whereArgs: [row['id']]);
        }
        for (final row in topicRows) {
          await txn.delete('tb_reading_topic_sources',
              where: 'topic_id = ?', whereArgs: [row['id']]);
        }
        await txn.delete('tb_reading_card_reviews',
            where: 'book_id = ?', whereArgs: [bookId]);
        await txn.delete('tb_reading_knowledge_cards',
            where: 'book_id = ?', whereArgs: [bookId]);
        await txn.delete('tb_reading_memory_topics',
            where: 'book_id = ?', whereArgs: [bookId]);
        await txn.delete('tb_reading_memory_sources',
            where: 'book_id = ?', whereArgs: [bookId]);
      });
  Future<List<String>> _relationIds(
          String table, String ownerColumn, String ownerId) async =>
      rawQueryList('SELECT source_id FROM $table WHERE $ownerColumn = ?',
          arguments: [ownerId], mapper: (row) => row['source_id'].toString());
}

final readingMemoryDao = ReadingMemoryDao();
