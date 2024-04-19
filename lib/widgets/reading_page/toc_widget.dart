import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:flutter/material.dart';

import '../../main.dart';
import '../../models/toc_item.dart';
import '../../page/book_player/epub_player.dart';

class TocWidget extends StatelessWidget {
  const TocWidget({
    super.key,
    required this.tocItems,
    required this.epubPlayerKey,
    required this.hideAppBarAndBottomBar,
  });

  final List<TocItem> tocItems;
  final epubPlayerKey;
  final hideAppBarAndBottomBar;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: Text(
            context.readingContents,
            style: const TextStyle(
              fontSize: 30,
              fontWeight: FontWeight.bold,
              fontFamily: 'SourceHanSerif'
            ),
          ),
        ),
        Container(
          // decoration: const BoxDecoration(
          //   color: Colors.white,
          //   borderRadius: BorderRadius.only(
          //     topLeft: Radius.circular(20),
          //     topRight: Radius.circular(20),
          //   ),
          // ),
          height: 600,
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
    fontSize: 20,
    color: Theme.of(context).colorScheme.primary,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          height: 50,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // SizedBox(width: 1),
              TextButton(
                onPressed: () {
                  widget.hideAppBarAndBottomBar(false);
                  widget.epubPlayerKey.currentState!.goTo(widget.tocItem.href);
                },
                style: ButtonStyle(
                  padding: MaterialStateProperty.all(EdgeInsets.zero),
                  alignment: Alignment.centerLeft,
                ),
                child: Text(
                  '     ${widget.tocItem.label.trim()}',
                    style: _isSelected(widget.tocItem)
                      ? tocStyleSelected(context)
                      : tocStyle(context),
                ),
              ),
              if (widget.tocItem.subitems.isNotEmpty)
                IconButton(
                  icon:
                      Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () {
                    setState(() {
                      _isExpanded = !_isExpanded;
                    });
                  },
                ),
            ],
          ),
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
        Divider(indent: 20, endIndent: 20, thickness: 1, color: Colors.grey.shade400),
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
