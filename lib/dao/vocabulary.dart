import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/vocabulary_item.dart';
import 'package:sqflite/sqflite.dart';

class VocabularyDao extends BaseDao {
  VocabularyDao();

  static const String table = 'tb_vocabulary';

  Future<VocabularyItem?> selectByWord(String word) {
    final normalizedWord = VocabularyItem.normalizeWord(word);
    if (normalizedWord.isEmpty) {
      return Future.value(null);
    }

    return querySingle(
      table,
      mapper: VocabularyItem.fromDb,
      where: 'normalized_word = ?',
      whereArgs: [normalizedWord],
    );
  }

  Future<bool> exists(String word) async {
    return await selectByWord(word) != null;
  }

  Future<VocabularyItem> save(VocabularyItem item) async {
    final existing = await selectByWord(item.word);
    if (existing != null) {
      return existing;
    }

    await insert(
      table,
      item.toDb(),
      conflictAlgorithm: ConflictAlgorithm.ignore,
    );

    return await selectByWord(item.word) ?? item;
  }

  Future<List<VocabularyItem>> selectAll() {
    return queryList(
      table,
      mapper: VocabularyItem.fromDb,
      orderBy: 'created_at DESC',
    );
  }

  Future<List<VocabularyItem>> selectDue({DateTime? now}) {
    final target = now ?? DateTime.now();
    return queryList(
      table,
      mapper: VocabularyItem.fromDb,
      where: 'is_mastered = 0 AND next_review_at <= ?',
      whereArgs: [target.toIso8601String()],
      orderBy: 'next_review_at ASC, created_at DESC',
    );
  }

  Future<int> upsertFromSync(List<VocabularyItem> items) async {
    final db = await database;
    return db.transaction((txn) async {
      var changed = 0;

      for (final item in items) {
        final normalizedWord = VocabularyItem.normalizeWord(item.word);
        if (normalizedWord.isEmpty) continue;

        final existingRows = await txn.query(
          table,
          where: 'normalized_word = ?',
          whereArgs: [normalizedWord],
          limit: 1,
        );

        if (existingRows.isEmpty) {
          final inserted = await txn.insert(
            table,
            item.toDb(),
            conflictAlgorithm: ConflictAlgorithm.ignore,
          );
          if (inserted > 0) changed++;
          continue;
        }

        final existing = VocabularyItem.fromDb(existingRows.first);
        if (!item.updatedAt.isAfter(existing.updatedAt)) {
          continue;
        }

        final createdAt = item.createdAt.isBefore(existing.createdAt)
            ? item.createdAt
            : existing.createdAt;
        final values = item
            .copyWith(
              id: existing.id,
              createdAt: createdAt,
            )
            .toDb();
        final updated = await txn.update(
          table,
          values,
          where: 'normalized_word = ?',
          whereArgs: [normalizedWord],
        );
        if (updated > 0) changed++;
      }

      return changed;
    });
  }

  Future<int> countDue({DateTime? now}) async {
    final target = now ?? DateTime.now();
    final result = await rawQuerySingle(
      'SELECT COUNT(*) AS count FROM $table WHERE is_mastered = 0 AND next_review_at <= ?',
      arguments: [target.toIso8601String()],
      mapper: (row) => row['count'] as int? ?? 0,
    );
    return result ?? 0;
  }

  Future<int> countMastered() async {
    final result = await rawQuerySingle(
      'SELECT COUNT(*) AS count FROM $table WHERE is_mastered = 1',
      mapper: (row) => row['count'] as int? ?? 0,
    );
    return result ?? 0;
  }

  Future<void> updateItem(VocabularyItem item) {
    return update(
      table,
      item.copyWith(updatedAt: DateTime.now()).toDb(),
      where: 'id = ?',
      whereArgs: [item.id],
    );
  }

  Future<void> deleteById(String id) {
    return delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }
}

final vocabularyDao = VocabularyDao();
