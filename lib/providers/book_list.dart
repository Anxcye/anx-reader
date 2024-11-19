import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/models/book.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_list.g.dart';

// @riverpod
// Future<List<Book>> bookList(Ref ref) async {
//   final books = await selectBooks();
//   return books;
// }

@riverpod
class BookList extends _$BookList {
  @override
  Future<List<Book>> build() async {
    final books = await selectNotDeleteBooks();
    return books;
  }

  Future<void> refresh() async {
    final books = await selectNotDeleteBooks();
    state = AsyncData(books);
  }
}
