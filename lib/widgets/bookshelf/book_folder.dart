import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/tb_group.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/tb_groups.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/bookshelf/book_item.dart';
import 'package:anx_reader/widgets/bookshelf/book_opened_folder.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookFolder extends ConsumerStatefulWidget {
  const BookFolder({
    super.key,
    required this.books,
  });

  final List<Book> books;

  @override
  ConsumerState<BookFolder> createState() => _BookFolderState();
}

class _BookFolderState extends ConsumerState<BookFolder> {
  bool willAcceptBook = false;

  @override
  Widget build(BuildContext context) {
    void onAcceptBook(DragTargetDetails<Book> details) {
      int targetGroupId;
      if (widget.books.first.groupId == 0) {
        ref.read(bookListProvider.notifier).updateBook(
            widget.books.first.copyWith(groupId: widget.books.first.id));
        targetGroupId = widget.books.first.id;
      } else {
        targetGroupId = widget.books.first.groupId;
      }
      ref.read(bookListProvider.notifier).moveBook(details.data, targetGroupId);
    }

    Widget scaleTransition(Widget child) {
      return willAcceptBook
          ? ScaleTransition(
              scale: Tween<double>(begin: 1.0, end: 1.1).animate(
                CurvedAnimation(
                    parent: const AlwaysStoppedAnimation(0.5),
                    curve: Curves.easeInOut),
              ),
              child: child,
            )
          : child;
    }

    bool onWillAcceptBook(DragTargetDetails<Book>? details) {
      if (details?.data.id == widget.books.first.id) {
        return false;
      }
      willAcceptBook = details?.data != null;
      return details?.data != null;
    }

    void onLeaveBook(Book? book) {
      willAcceptBook = false;
    }

    void openFolder(String groupName) {
      showDialog(
        context: context,
        builder: (context) => BookOpenedFolder(
          books: widget.books,
          groupName: groupName,
        ),
      );
    }

    String groupName = ref.watch(groupDaoProvider).whenOrNull(
              data: (groups) => groups
                  .firstWhere((group) => group.id == widget.books.first.groupId,
                      orElse: () => TbGroup(id: -1, name: "..."))
                  .name,
            ) ??
        '???';

    return widget.books.length == 1
        ? DragTarget<Book>(
            onAcceptWithDetails: (book) => onAcceptBook(book),
            onWillAcceptWithDetails: (data) => onWillAcceptBook(data),
            onLeave: (data) => onLeaveBook(data),
            builder: (context, candidateData, rejectedData) {
              return scaleTransition(BookItem(book: widget.books[0]));
            },
          )
        : DragTarget<Book>(
            onAcceptWithDetails: (book) => onAcceptBook(book),
            onWillAcceptWithDetails: (data) => onWillAcceptBook(data),
            onLeave: (data) => onLeaveBook(data),
            builder: (context, candidateData, rejectedData) {
              double topPosition = -10;
              return scaleTransition(
                Column(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () => openFolder(groupName),
                        child: Stack(
                          children: [
                            ...(widget.books.length >= 4
                                    ? widget.books.sublist(0, 4)
                                    : widget.books)
                                .reversed
                                .map((book) {
                              topPosition += 10;
                              return Positioned.fill(
                                right: 0,
                                top: topPosition,
                                child: Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(10),
                                    border: Border.all(
                                      color: Theme.of(context)
                                          .colorScheme
                                          .outlineVariant,
                                      width: 1,
                                    ),
                                  ),
                                  child: bookCover(context, book),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),
                    Text(
                      groupName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              );
            },
          );
  }
}
