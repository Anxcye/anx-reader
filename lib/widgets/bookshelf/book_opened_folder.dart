import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/widgets/bookshelf/book_item.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookOpenedFolder extends ConsumerStatefulWidget {
  const BookOpenedFolder({super.key, required this.books});
  final List<Book> books;

  @override
  ConsumerState<BookOpenedFolder> createState() => _BookOpenedFolderState();
}

class _BookOpenedFolderState extends ConsumerState<BookOpenedFolder> {
  bool isEditing = false;
  List<Book> books = [];

  @override
  void initState() {
    super.initState();
    books = widget.books;
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.7,
        child: GridView.builder(
            shrinkWrap: true,
            gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
              maxCrossAxisExtent: 100,
              childAspectRatio: 1 / 1.9,
              crossAxisSpacing: 10,
              mainAxisSpacing: 10,
            ),
            itemCount: books.length,
            itemBuilder: (context, index) => Stack(
                  children: [
                    BookItem(book: books[index]),
                    isEditing
                        ? Positioned(
                            right: 0,
                            top: 0,
                            child: IconButton(
                              onPressed: () {
                                ref
                                    .read(bookListProvider.notifier)
                                    .removeFromGroup(books[index]);
                                books.removeAt(index);
                                if (books.isEmpty) {
                                  Navigator.pop(context);
                                }
                                setState(() {});
                              },
                              icon: const Icon(
                                Icons.remove_circle,
                                size: 30,
                                color: Colors.red,
                              ),
                            ),
                          )
                        : Container(),
                  ],
                )),
      ),
      actions: [
        TextButton(
            onPressed: () {
              ref.read(bookListProvider.notifier).dissolveGroup(books);
              Navigator.pop(context);
            },
            child: Text(L10n.of(context).common_dissolve)),
        TextButton(
            onPressed: () {
              isEditing = !isEditing;
              setState(() {});
            },
            child: Text(isEditing
                ? L10n.of(context).common_cancel
                : L10n.of(context).common_edit)),
      ],
    );
  }
}
