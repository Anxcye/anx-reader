import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/dao/reading_time.dart';
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
  Future<List<Map<String, int>>> build() async {
    return _getBookIdAndNotes();
  }

  Future<List<Map<String, int>>> _getBookIdAndNotes() async {
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
