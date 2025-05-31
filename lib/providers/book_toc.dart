import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'book_toc.g.dart';

@Riverpod(keepAlive: true)
class BookToc extends _$BookToc {
  @override
  List<TocItem> build() {
    return [];
  }

  void setToc(List<TocItem> tocItems) {
    state = tocItems;
  }

  Future<void> refresh(String bookId) async {
    epubPlayerKey.currentState?.refreshToc();
  }
}
