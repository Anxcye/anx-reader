import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/tag.dart';
import 'package:anx_reader/enums/sort_field.dart';
import 'package:anx_reader/enums/sort_order.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/providers/tb_groups.dart';
import 'package:anx_reader/providers/book_filters.dart';
import 'package:anx_reader/providers/tags.dart'
    show kNoTagFilterId, tagSelectionProvider;
import 'package:lpinyin/lpinyin.dart';
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

  int getChineseCompareResult(String a, String b) {
    String pinyina = '';
    String pinyinb = '';
    try {
      pinyina = PinyinHelper.getPinyin(a, format: PinyinFormat.WITHOUT_TONE);
    } catch (e) {
      pinyina = a;
    }
    try {
      pinyinb = PinyinHelper.getPinyin(b, format: PinyinFormat.WITHOUT_TONE);
    } catch (e) {
      pinyinb = b;
    }

    return pinyina.compareTo(pinyinb);
  }

  List<Book> sortBooks(List<Book> books) {
    books.sort((a, b) {
      int compareResult;
      switch (Prefs().sortField) {
        case SortFieldEnum.title:
          compareResult = getChineseCompareResult(a.title, b.title);
          break;
        case SortFieldEnum.author:
          compareResult = getChineseCompareResult(a.author, b.author);
          break;
        case SortFieldEnum.lastReadTime:
          compareResult = a.updateTime.compareTo(b.updateTime);
          break;
        case SortFieldEnum.progress:
          compareResult = a.readingPercentage.compareTo(b.readingPercentage);
          break;
        case SortFieldEnum.importTime:
          compareResult = a.createTime.compareTo(b.createTime);
          break;
      }
      return Prefs().sortOrder == SortOrderEnum.ascending
          ? compareResult
          : -compareResult;
    });
    return books;
  }

  bool _matchesStatus(Book book, ReadingStatusFilter status) {
    const notStartThreshold = 0.02;
    const finishedThreshold = 0.98;
    switch (status) {
      case ReadingStatusFilter.none:
        return true;
      case ReadingStatusFilter.finished:
        return book.readingPercentage >= finishedThreshold;
      case ReadingStatusFilter.reading:
        return book.readingPercentage > notStartThreshold &&
            book.readingPercentage < finishedThreshold;
      case ReadingStatusFilter.notStarted:
        return book.readingPercentage <= notStartThreshold;
    }
  }

  Future<List<List<Book>>> _buildWithFilters({String? query}) async {
    final status = ref.watch(readingStatusFilterNotifierProvider);
    final selectedTags = ref.watch(tagSelectionProvider);

    final books = await bookDao.selectNotDeleteBooks();
    final filteredByQuery = query == null || query.isEmpty
        ? books
        : books
            .where(
              (book) =>
                  book.title.contains(query) || book.author.contains(query),
            )
            .toList();

    final filteredByStatus =
        filteredByQuery.where((book) => _matchesStatus(book, status)).toList();

    List<Book> filteredByTags = filteredByStatus;
    if (selectedTags.isNotEmpty) {
      final tagMap = await bookTagDao.bookIdToTagIds(
          bookIds: filteredByStatus.map((b) => b.id).toList());
      if (selectedTags.contains(kNoTagFilterId)) {
        // Filter books without any tags
        filteredByTags = filteredByStatus.where((book) {
          final tags = tagMap[book.id];
          return tags == null || tags.isEmpty;
        }).toList();
      } else {
        // Filter books that contain all selected tags
        filteredByTags = filteredByStatus.where((book) {
          final tags = tagMap[book.id];
          if (tags == null || tags.isEmpty) return false;
          return selectedTags.every((id) => tags.contains(id));
        }).toList();
      }
    }

    final sortedBooks = sortBooks(filteredByTags);
    return groupBooks(sortedBooks);
  }

  @override
  Future<List<List<Book>>> build() async {
    return _buildWithFilters();
  }

  Future<void> refresh() async {
    state = AsyncData(await _buildWithFilters());
  }

  void moveBook(Book data, int groupId) {
    updateBook(data.copyWith(groupId: groupId));
    // insert a new group if not exists
    ref.read(groupDaoProvider.notifier).insertGroup(groupId);
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
    // delete the group
    ref.read(groupDaoProvider.notifier).hardDeleteGroup(books.first.groupId);
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
    state = AsyncData(await _buildWithFilters(query: value));
  }
}
