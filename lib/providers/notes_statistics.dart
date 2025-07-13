import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/models/book.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'notes_statistics.g.dart';

@riverpod
class NotesStatistics extends _$NotesStatistics {
  @override
  Future<Map<String, int>> build() async {
    return _getNotesStatistics();
  }

  Future<Map<String, int>> _getNotesStatistics() async {
    return await selectNumberOfNotesAndBooks();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _getNotesStatistics());
  }
}

@riverpod
class BookIdAndNotes extends _$BookIdAndNotes {
  @override
  Future<List<Map<String, dynamic>>> build() async {
    final bookDataList = await _getBookIdAndNotes();
    final result = <Map<String, dynamic>>[];

    for (final data in bookDataList) {
      Book book = await selectBookById(data['bookId']);
      int readingTime = await selectTotalReadingTimeByBookId(book.id);
      result.add({
        'bookId': data['bookId'],
        'numberOfNotes': data['numberOfNotes'],
        'book': book,
        'readingTime': readingTime,
      });
    }

    return result;
  }

  Future<List<Map<String, dynamic>>> _getBookIdAndNotes() async {
    return await selectAllBookIdAndNotes();
  }

  Future<void> refresh() async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _getBookIdAndNotes());
  }
}

@riverpod
class BookReadingTime extends _$BookReadingTime {
  @override
  Future<int> build(int bookId) async {
    return _getBookReadingTime(bookId);
  }

  Future<int> _getBookReadingTime(int bookId) async {
    return await selectTotalReadingTimeByBookId(bookId);
  }

  Future<void> refresh(int bookId) async {
    state = const AsyncValue.loading();
    state = AsyncValue.data(await _getBookReadingTime(bookId));
  }
}
