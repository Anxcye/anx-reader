import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:sqflite/sqflite.dart';

class ReadingNoteDao extends BaseDao {
  ReadingNoteDao({super.databaseProvider});

  Future<List<ReadingNote>> notes({
    int? bookId,
    ReadingNoteStatus? status,
  }) {
    final where = <String>[];
    final args = <Object?>[];
    if (bookId != null) {
      where.add('book_id = ?');
      args.add(bookId);
    }
    if (status != null) {
      where.add('status = ?');
      args.add(status.name);
    } else {
      where.add("status != 'trashed'");
    }
    return queryList(
      'tb_reading_notes',
      mapper: ReadingNote.fromDb,
      where: where.join(' AND '),
      whereArgs: args,
      orderBy: 'updated_at DESC',
    );
  }

  Future<ReadingNote?> note(String id) => querySingle(
        'tb_reading_notes',
        mapper: ReadingNote.fromDb,
        where: 'id = ?',
        whereArgs: [id],
      );

  Future<List<ReadingNoteBlock>> blocks(String noteId) => queryList(
        'tb_reading_note_blocks',
        mapper: ReadingNoteBlock.fromDb,
        where: 'note_id = ?',
        whereArgs: [noteId],
        orderBy: 'sort_order ASC',
      );

  Future<List<ReadingNoteSource>> sources(String noteId) => queryList(
        'tb_reading_note_sources',
        mapper: ReadingNoteSource.fromDb,
        where: 'note_id = ?',
        whereArgs: [noteId],
      );

  Future<List<ReadingNoteTag>> tags({String? noteId}) async {
    if (noteId == null) {
      return queryList('tb_reading_tags',
          mapper: ReadingNoteTag.fromDb, orderBy: 'name COLLATE NOCASE ASC');
    }
    return rawQueryList(
      '''SELECT t.* FROM tb_reading_tags t
         JOIN tb_reading_note_tags nt ON nt.tag_id = t.id
         WHERE nt.note_id = ? ORDER BY t.name COLLATE NOCASE ASC''',
      arguments: [noteId],
      mapper: ReadingNoteTag.fromDb,
    );
  }

  Future<List<ReadingNoteRevision>> revisions(String noteId) => queryList(
        'tb_reading_note_revisions',
        mapper: ReadingNoteRevision.fromDb,
        where: 'note_id = ?',
        whereArgs: [noteId],
        orderBy: 'created_at DESC',
      );

  Future<String?> mappedAnnotationId(int annotationId) async {
    final row = await rawQuerySingle(
      '''SELECT note_id FROM tb_reading_note_sources
         WHERE source_type = 'annotation' AND source_ref = ? LIMIT 1''',
      arguments: [annotationId.toString()],
      mapper: (row) => row['note_id']?.toString(),
    );
    return row;
  }

  Future<void> createDocument(ReadingNoteDocument document) =>
      transaction((txn) async {
        await txn.insert('tb_reading_notes', document.note.toDb(),
            conflictAlgorithm: ConflictAlgorithm.ignore);
        for (final block in document.blocks) {
          await txn.insert('tb_reading_note_blocks', block.toDb(),
              conflictAlgorithm: ConflictAlgorithm.replace);
        }
        for (final source in document.sources) {
          await txn.insert('tb_reading_note_sources', source.toDb(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });

  Future<void> saveDocument({
    required ReadingNote note,
    required ReadingNoteBlock textBlock,
    required List<ReadingNoteTag> tags,
    ReadingNoteRevision? revision,
    int? annotationId,
  }) =>
      transaction((txn) async {
        await txn.update('tb_reading_notes', note.toDb(),
            where: 'id = ?', whereArgs: [note.id]);
        await txn.insert('tb_reading_note_blocks', textBlock.toDb(),
            conflictAlgorithm: ConflictAlgorithm.replace);
        await txn.delete('tb_reading_note_tags',
            where: 'note_id = ?', whereArgs: [note.id]);
        for (final tag in tags) {
          await txn.insert('tb_reading_tags', tag.toDb(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
          await txn.insert(
              'tb_reading_note_tags', {'note_id': note.id, 'tag_id': tag.id},
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
        if (revision != null) {
          await txn.insert('tb_reading_note_revisions', revision.toDb());
        }
        if (annotationId != null) {
          await txn.update(
              'tb_notes',
              {
                'reader_note': textBlock.content,
                'update_time':
                    DateTime.fromMillisecondsSinceEpoch(note.updatedAt)
                        .toIso8601String(),
              },
              where: 'id = ?',
              whereArgs: [annotationId]);
        }
      });

  Future<void> updateNote(ReadingNote note) => update(
        'tb_reading_notes',
        note.toDb(),
        where: 'id = ?',
        whereArgs: [note.id],
      );

  Future<void> saveBlock(ReadingNoteBlock block) => insert(
        'tb_reading_note_blocks',
        block.toDb(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      ).then((_) {});

  Future<void> deleteBlock(String blockId) => delete(
        'tb_reading_note_blocks',
        where: 'id = ?',
        whereArgs: [blockId],
      ).then((_) {});

  Future<void> saveSources(List<ReadingNoteSource> items) =>
      transaction((txn) async {
        for (final item in items) {
          await txn.insert('tb_reading_note_sources', item.toDb(),
              conflictAlgorithm: ConflictAlgorithm.ignore);
        }
      });

  Future<void> deletePermanently(String noteId) => transaction((txn) async {
        await txn.delete('tb_reading_note_tags',
            where: 'note_id = ?', whereArgs: [noteId]);
        await txn.delete('tb_reading_note_revisions',
            where: 'note_id = ?', whereArgs: [noteId]);
        await txn.delete('tb_reading_note_sources',
            where: 'note_id = ?', whereArgs: [noteId]);
        await txn.delete('tb_reading_note_blocks',
            where: 'note_id = ?', whereArgs: [noteId]);
        await txn
            .delete('tb_reading_notes', where: 'id = ?', whereArgs: [noteId]);
      });

  Future<void> deleteBookNotes(int bookId) => transaction((txn) async {
        await txn.delete('tb_reading_note_ai_suggestions',
            where: 'book_id = ?', whereArgs: [bookId]);
        await txn.delete('tb_reading_note_ai_batches',
            where: 'book_id = ?', whereArgs: [bookId]);
        final rows = await txn.query('tb_reading_notes',
            columns: ['id'], where: 'book_id = ?', whereArgs: [bookId]);
        for (final row in rows) {
          final id = row['id'];
          for (final table in [
            'tb_reading_note_tags',
            'tb_reading_note_revisions',
            'tb_reading_note_sources',
            'tb_reading_note_blocks',
          ]) {
            await txn.delete(table, where: 'note_id = ?', whereArgs: [id]);
          }
        }
        await txn.delete('tb_reading_notes',
            where: 'book_id = ?', whereArgs: [bookId]);
      });
}

final readingNoteDaoInstance = ReadingNoteDao();
