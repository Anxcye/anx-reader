import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/reading_note_ai.dart';
import 'package:sqflite/sqflite.dart';

class ReadingNoteAiDao extends BaseDao {
  ReadingNoteAiDao({super.databaseProvider});

  Future<List<ReadingNoteAiBatch>> batches(int bookId) => queryList(
        'tb_reading_note_ai_batches',
        mapper: ReadingNoteAiBatch.fromDb,
        where: 'book_id = ?',
        whereArgs: [bookId],
        orderBy: 'updated_at DESC',
      );

  Future<ReadingNoteAiBatch?> batch(String id) => querySingle(
        'tb_reading_note_ai_batches',
        mapper: ReadingNoteAiBatch.fromDb,
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<List<ReadingNoteAiSuggestion>> suggestions(String batchId) =>
      queryList(
        'tb_reading_note_ai_suggestions',
        mapper: ReadingNoteAiSuggestion.fromDb,
        where: 'batch_id = ?',
        whereArgs: [batchId],
        orderBy: 'created_at ASC',
      );

  Future<void> saveBatch(ReadingNoteAiBatch batch) => insert(
        'tb_reading_note_ai_batches',
        batch.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ).then((_) {});

  Future<void> updateBatch(ReadingNoteAiBatch batch) => update(
        'tb_reading_note_ai_batches',
        batch.toDb(),
        where: 'id = ?',
        whereArgs: [batch.id],
      ).then((_) {});

  Future<void> saveSuggestions(List<ReadingNoteAiSuggestion> items) =>
      transaction((txn) async {
        for (final item in items) {
          await txn.insert('tb_reading_note_ai_suggestions', item.toDb(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
      });

  Future<void> updateSuggestion(ReadingNoteAiSuggestion item) => update(
        'tb_reading_note_ai_suggestions',
        item.toDb(),
        where: 'id = ?',
        whereArgs: [item.id],
      ).then((_) {});

  Future<void> archivePendingSources(
          int bookId, List<(ReadingNoteAiSourceType, String)> sources) =>
      transaction((txn) async {
        final now = DateTime.now().millisecondsSinceEpoch;
        for (final source in sources) {
          await txn.update(
            'tb_reading_note_ai_suggestions',
            {
              'status': ReadingNoteAiSuggestionStatus.archived.name,
              'updated_at': now
            },
            where:
                'book_id = ? AND source_type = ? AND source_ref = ? AND status = ?',
            whereArgs: [
              bookId,
              source.$1.name,
              source.$2,
              ReadingNoteAiSuggestionStatus.pending.name,
            ],
          );
        }
      });

  Future<void> clearPendingPayload(String batchId) => transaction((txn) async {
        await txn.delete(
          'tb_reading_note_ai_suggestions',
          where: 'batch_id = ? AND status IN (?, ?, ?)',
          whereArgs: [
            batchId,
            ReadingNoteAiSuggestionStatus.pending.name,
            ReadingNoteAiSuggestionStatus.ignored.name,
            ReadingNoteAiSuggestionStatus.archived.name,
          ],
        );
      });

  Future<void> deleteBookOrganizerData(int bookId) => transaction((txn) async {
        await txn.delete('tb_reading_note_ai_suggestions',
            where: 'book_id = ?', whereArgs: [bookId]);
        await txn.delete('tb_reading_note_ai_batches',
            where: 'book_id = ?', whereArgs: [bookId]);
      });
}

final readingNoteAiDao = ReadingNoteAiDao();
