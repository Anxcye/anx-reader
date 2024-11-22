import 'package:anx_reader/dao/book.dart' as bookDao;
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
  Future<List<List<Book>>> build() async {
    final books = await bookDao.selectNotDeleteBooks();
    var groupBooks = <List<Book>>[];
    for (var book in books) {
      if (book.groupId == 0) {
        groupBooks.add([book]);
      } else {
        var existingGroup = groupBooks.firstWhere(
          (group) => group.first.groupId == book.groupId,
          orElse: () => [],
        );
        if (existingGroup.isEmpty) {
          groupBooks.add([book]);
        } else {
          existingGroup.add(book);
        }
      }
    }
    return groupBooks;
  }

  Future<void> refresh() async {
    // ignore: invalid_use_of_protected_member
    state = AsyncData(await build());
  }

  void moveBook(Book data, int groupId) {
    updateBook(data.copyWith(groupId: groupId));
    refresh();
  }

  void updateBook(Book book) {
    bookDao.updateBook(book);
    refresh();
  }

  void dissolveGroup(List<Book> books) {
    for (var book in books) {
      updateBook(book.copyWith(groupId: 0));
    }
    refresh();
  }

  void removeFromGroup(Book book) {
    updateBook(book.copyWith(groupId: 0));
    refresh();
  }
}
