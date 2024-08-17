import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/reading_page/widget_title.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:flutter/material.dart';

class TocWidget extends StatelessWidget {
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
  Widget build(BuildContext context) {
    return SizedBox(
      height: 600,
      child: Column(
        children: [
          widgetTitle(L10n.of(context).reading_contents, null),
          Expanded(
            child: ListView.builder(
              itemCount: tocItems.length,
              itemBuilder: (context, index) {
                return TocItemWidget(
                    tocItem: tocItems[index],
                    hideAppBarAndBottomBar: hideAppBarAndBottomBar,
                    epubPlayerKey: epubPlayerKey);
              },
            ),
          ),
        ],
      ),
    );
  }
}

class TocItemWidget extends StatefulWidget {
  final TocItem tocItem;
  final Function hideAppBarAndBottomBar;
  final GlobalKey<EpubPlayerState> epubPlayerKey;

  const TocItemWidget(
      {super.key,
      required this.tocItem,
      required this.hideAppBarAndBottomBar,
      required this.epubPlayerKey});

  @override
  _TocItemWidgetState createState() => _TocItemWidgetState();
}

class _TocItemWidgetState extends State<TocItemWidget> {
  bool _isExpanded = false;

  TextStyle tocStyle(content) => TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface,
      );

  TextStyle tocStyleSelected(context) => TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: TextButton(
                onPressed: () {
                  widget.hideAppBarAndBottomBar(false);
                  widget.epubPlayerKey.currentState!
                      .goToHref(widget.tocItem.href);
                },
                style: const ButtonStyle(
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  widget.tocItem.label.trim(),
                  style: _isSelected(widget.tocItem)
                      ? tocStyleSelected(context)
                      : tocStyle(context),
                ),
              ),
            ),
            if (widget.tocItem.subitems.isNotEmpty)
              IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
          ],
        ),
        if (_isExpanded)
          for (var subItem in widget.tocItem.subitems)
            Padding(
              padding: const EdgeInsets.only(left: 26.0),
              child: TocItemWidget(
                  tocItem: subItem,
                  hideAppBarAndBottomBar: widget.hideAppBarAndBottomBar,
                  epubPlayerKey: widget.epubPlayerKey),
            ),
        Divider(
            indent: 10,
            endIndent: 20,
            thickness: 1,
            color: Colors.grey.shade400),
      ],
    );
  }

  bool _isSelected(TocItem tocItem) {
    if (tocItem.href == widget.epubPlayerKey.currentState!.chapterHref) {
      return true;
    }
    for (var subItem in tocItem.subitems) {
      if (_isSelected(subItem)) {
        return true;
      }
    }
    return false;
  }
}
