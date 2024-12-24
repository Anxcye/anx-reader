import 'package:anx_reader/dao/book.dart' as bookDao;
import 'package:anx_reader/models/book.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_list.g.dart';

@riverpod
class BookList extends _$BookList {
  List<List<Book>> groupBooks(List<Book> books) {
    var groupedBooks = <List<Book>>[];
    for (var book in books) {
      if (book.groupId == 0) {
        groupedBooks.add([book]);
      } else {
        var existingGroup = groupedBooks.firstWhere(
          (group) => group.first.groupId == book.groupId,
          orElse: () => [],
        );
        if (existingGroup.isEmpty) {
          groupedBooks.add([book]);
        } else {
          existingGroup.add(book);
        }
      }
    }
    return groupedBooks;
  }

  @override
  Future<List<List<Book>>> build() async {
    final books = await bookDao.selectNotDeleteBooks();
    return groupBooks(books);
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

  void reorder(List<List<Book>> books) {
    state = AsyncData(books);
  }

  void moveBookToTop(int bookId) {
    var groups = state.value!.map((group) {
      if (group.any((book) => book.id == bookId)) {
        return [
          group.firstWhere((book) => book.id == bookId),
          ...group.where((b) => b.id != bookId)
        ];
      }
      return group;
    }).toList();

    state = AsyncData([
      groups.firstWhere((group) => group.any((book) => book.id == bookId)),
      ...groups.where((group) => group.every((book) => book.id != bookId))
    ]);
  }

  Future<void> search(String? value) async {
    if (value == null || value.isEmpty) {
      state = AsyncData(await build());
      return;
    }

    final books = await bookDao.selectNotDeleteBooks();

    final filteredBooks = books.where((book) {
      return book.title.contains(value) || book.author.contains(value);
    }).toList();

    final groupedBooks = groupBooks(filteredBooks);
    state = AsyncData(groupedBooks);
  }
}
