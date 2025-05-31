import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/widgets/reading_page/widgets/book_toc.dart';
import 'package:anx_reader/widgets/reading_page/widgets/bookmark.dart';
import 'package:flutter/material.dart';

class TocWidget extends StatefulWidget {
  const TocWidget({
    super.key,
    required this.tocItems,
    required this.epubPlayerKey,
    required this.hideAppBarAndBottomBar,
  });

  final List<TocItem> tocItems;
  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final Function hideAppBarAndBottomBar;

  @override
  State<TocWidget> createState() => _TocWidgetState();
}

class _TocWidgetState extends State<TocWidget>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: MediaQuery.of(context).size.height - 200,
      child: Column(
        children: [
          TabBar(
            controller: _tabController,
            tabs: [
              Tab(text: L10n.of(context).reading_contents),
              Tab(text: L10n.of(context).reading_bookmark),
            ],
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: TabBarView(
                controller: _tabController,
                children: [
                  buildBookToc(),
                  buildBookmarkList(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget buildBookmarkList() {
    return BookmarkWidget(epubPlayerKey: widget.epubPlayerKey);
  }

  BookToc buildBookToc() {
    return BookToc(
        tocItems: widget.tocItems,
        epubPlayerKey: widget.epubPlayerKey,
        hideAppBarAndBottomBar: widget.hideAppBarAndBottomBar);
  }
}
