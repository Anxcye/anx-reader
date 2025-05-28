import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/bookmark.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/providers/bookmark.dart';
import 'package:anx_reader/utils/error_handler.dart';
import 'package:anx_reader/widgets/container/filled_container.dart';
import 'package:anx_reader/widgets/delete_confirm.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookmarkWidget extends ConsumerStatefulWidget {
  const BookmarkWidget({
    super.key,
    required this.epubPlayerKey,
  });

  final GlobalKey<EpubPlayerState> epubPlayerKey;

  @override
  ConsumerState<BookmarkWidget> createState() => _BookmarkWidgetState();
}

class _BookmarkWidgetState extends ConsumerState<BookmarkWidget> {
  @override
  Widget build(BuildContext context) {
    final bookId = widget.epubPlayerKey.currentState!.book.id;

    final bookmarkList = ref.watch(BookmarkProvider(bookId));
    return bookmarkList.when(
      data: (bookmarks) {
        if (bookmarks.isEmpty) {
          return Center(
            child: Column(
              children: [
                Text(
                  L10n.of(context).no_bookmarks,
                  style: Theme.of(context).textTheme.titleLarge!.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                ),
                SizedBox(height: 16.0),
                Text(L10n.of(context).no_bookmarks_tip),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: BookmarkItem(
                bookmark: bookmark,
                onTap: (cfi) {
                  widget.epubPlayerKey.currentState?.goToCfi(cfi);
                },
                onDelete: (id) {
                  ref.read(BookmarkProvider(bookId).notifier).removeBookmark(
                        id: id,
                      );
                },
              ),
            );
          },
        );
      },
      error: (error, stackTrace) {
        return errorHandler(error, stack: stackTrace);
      },
      loading: () {
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
    );
  }
}

class BookmarkItem extends StatelessWidget {
  const BookmarkItem({
    super.key,
    required this.bookmark,
    required this.onTap,
    required this.onDelete,
  });

  final BookmarkModel bookmark;
  final Function(String) onTap;
  final Function(int) onDelete;
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onTap(bookmark.cfi),
      child: FilledContainer(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              bookmark.content,
              style: TextStyle(
                fontSize: 16,
              ),
            ),
            const Divider(height: 2),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(bookmark.chapter,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                    Text('${bookmark.percentage.toStringAsFixed(2)}%',
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.onSurfaceVariant,
                        )),
                  ],
                ),
                DeleteConfirm(
                  delete: () {
                    onDelete(bookmark.id!);
                  },
                )
              ],
            ),
          ],
        ),
      ),
    );
  }
}
