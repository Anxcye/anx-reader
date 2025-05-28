import 'package:anx_reader/models/bookmark.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/providers/bookmark.dart';
import 'package:anx_reader/utils/error_handler.dart';
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
                Text('No Bookmarks'),
                Text(
                    'Pull down or click the bookmark icon in the top-right corner to add a bookmark.'),
              ],
            ),
          );
        }
        return ListView.builder(
          itemCount: bookmarks.length,
          itemBuilder: (context, index) {
            final bookmark = bookmarks[index];
            return BookmarkItem(
              bookmark: bookmark,
              onTap: (cfi) {
                widget.epubPlayerKey.currentState?.goToCfi(cfi);
              },
              onDelete: (id) {
                ref.read(BookmarkProvider(bookId).notifier).removeBookmark(
                      id,
                    );
              },
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
    return ListTile(
      title: Text(bookmark.content),
      subtitle: Text(bookmark.chapter),
      trailing: Text('${bookmark.percentage.toStringAsFixed(2)}%'),
      onTap: () => onTap(bookmark.cfi),
    );
  }
}
