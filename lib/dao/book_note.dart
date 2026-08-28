import 'package:anx_reader/dao/base_dao.dart';
import 'package:anx_reader/models/book_note.dart';

class BookNoteDao extends BaseDao {
  BookNoteDao({super.databaseProvider});

  static const String table = 'tb_notes';

  /// Annotation types for highlight/underline notes (excludes book reviews)
  static const List<String> annotationTypes = [
    'highlight',
    'underline',
    'bookmark'
  ];

  /// Helper to build type filter SQL
  static String get _typeFilter =>
      "type IN ('${annotationTypes.join("', '")}')";

  Future<int> save(BookNote bookNote) async {
    if (bookNote.id != null) {
      await updateBookNoteById(bookNote);
      return bookNote.id!;
    }

    final duplicates =
        await selectBookNoteByCfiAndBookId(bookNote.cfi, bookNote.bookId);
    if (duplicates.isNotEmpty) {
      bookNote.id = duplicates.last.id;
      await updateBookNoteById(bookNote);
      return bookNote.id!;
    }

    return insert(table, bookNote.toMap());
  }

  Future<List<BookNote>> selectBookNoteByCfiAndBookId(
      String cfi, int bookId) async {
    return queryList(
      table,
      mapper: BookNote.fromDb,
      where: 'cfi = ? AND book_id = ? AND $_typeFilter',
      whereArgs: [cfi, bookId],
      orderBy: 'update_time ASC',
    );
  }

  Future<List<BookNote>> selectBookNotesByBookId(int bookId) async {
    return queryList(
      table,
      mapper: BookNote.fromDb,
      where: 'book_id = ? AND $_typeFilter',
      whereArgs: [bookId],
      orderBy: 'update_time DESC',
    );
  }

  Future<void> updateBookNoteById(BookNote bookNote) async {
    await update(
      table,
      bookNote.toMap(),
      where: 'id = ?',
      whereArgs: [bookNote.id],
    );
  }

  Future<BookNote> selectBookNoteById(int id) async {
    final note = await querySingle(
      table,
      mapper: BookNote.fromDb,
      where: 'id = ?',
      whereArgs: [id],
    );

    if (note == null) {
      throw StateError('Book note with id $id not found');
    }

    return note;
  }

  Future<List<Map<String, int>>> selectAllBookIdAndNotes() async {
    return rawQueryList(
      'SELECT book_id, COUNT(id) AS number_of_notes FROM $table WHERE $_typeFilter GROUP BY book_id ORDER BY number_of_notes DESC',
      mapper: (row) => <String, int>{
        'bookId': row['book_id'] as int? ?? 0,
        'numberOfNotes': row['number_of_notes'] as int? ?? 0,
      },
    ).then((rows) => rows.where((element) => element['bookId'] != 0).toList());
  }

  Future<Map<String, int>> selectNumberOfNotesAndBooks() async {
    final result = await rawQuerySingle(
      'SELECT COUNT(id) AS number_of_notes, COUNT(DISTINCT book_id) AS number_of_books FROM $table WHERE $_typeFilter',
      mapper: (row) => <String, int>{
        'numberOfNotes': row['number_of_notes'] as int? ?? 0,
        'numberOfBooks': row['number_of_books'] as int? ?? 0,
      },
    );

    return result ?? const {'numberOfNotes': 0, 'numberOfBooks': 0};
  }

  Future<void> deleteBookNoteById(int id) async {
    await delete(
      table,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  Future<List<BookNote>> searchBookNotes(String keyword) {
    final query = keyword.trim();
    if (query.isEmpty) {
      return Future.value(const []);
    }
    return searchBookNotesAdvanced(keyword: query, types: annotationTypes);
  }

  Future<List<BookNote>> searchBookNotesAdvanced({
    String? keyword,
    int? bookId,
    DateTime? from,
    DateTime? to,
    int? limit,
    List<String>? types,
  }) async {
    final where = <String>[];
    final whereArgs = <Object?>[];
    final query = keyword?.trim();

    // Filter by types (defaults to annotation types if not specified)
    final filterTypes = types ?? annotationTypes;
    if (filterTypes.isNotEmpty) {
      where.add("type IN ('${filterTypes.join("', '")}')");
    }

    if (query != null && query.isNotEmpty) {
      where.add('(content LIKE ? OR reader_note LIKE ? OR chapter LIKE ?)');
      final pattern = '%$query%';
      whereArgs.addAll([pattern, pattern, pattern]);
    }

    if (bookId != null) {
      where.add('book_id = ?');
      whereArgs.add(bookId);
    }

    if (from != null) {
      where.add('update_time >= ?');
      whereArgs.add(from.toIso8601String());
    }

    if (to != null) {
      where.add('update_time <= ?');
      whereArgs.add(to.toIso8601String());
    }

    return queryList(
      table,
      mapper: BookNote.fromDb,
      where: where.isEmpty ? null : where.join(' AND '),
      whereArgs: whereArgs.isEmpty ? null : whereArgs,
      orderBy: 'update_time DESC',
      limit: limit,
    );
  }

  Future<BookNote?> selectRandomNote() async {
    return rawQuerySingle(
      'SELECT * FROM $table WHERE $_typeFilter ORDER BY RANDOM() LIMIT 1',
      mapper: BookNote.fromDb,
    );
  }
}

final bookNoteDao = BookNoteDao();
