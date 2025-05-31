import 'dart:math';

import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/search_result_model.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:flutter/material.dart';

class BookToc extends StatefulWidget {
  const BookToc({
    super.key,
    required this.tocItems,
    required this.epubPlayerKey,
    required this.hideAppBarAndBottomBar,
  });

  final List<TocItem> tocItems;
  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final Function hideAppBarAndBottomBar;

  @override
  State<BookToc> createState() => _BookTocState();
}

class _BookTocState extends State<BookToc> {
  String? _searchValue;
  TextEditingController searchBarController = TextEditingController();
  ScrollController listViewController = ScrollController();
  List<bool> isExpanded = [];

  @override
  void initState() {
    super.initState();
    for (var item in widget.tocItems) {
      isExpanded.add(_isSelected(item));
    }

    final offset = isExpanded.indexWhere((isExpanded) => isExpanded);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (listViewController.hasClients) {
        listViewController.jumpTo(
            min(offset * 48, listViewController.position.maxScrollExtent - 48));
      }
    });
  }

  @override
  void dispose() {
    _searchValue = null;
    searchBarController.clear();
    epubPlayerKey.currentState?.clearSearch();
    super.dispose();
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

  @override
  Widget build(BuildContext context) {
    var searchBox = SizedBox(
      height: 35,
      child: SearchBar(
        controller: searchBarController,
        shadowColor: const WidgetStatePropertyAll<Color>(Colors.transparent),
        padding: const WidgetStatePropertyAll<EdgeInsets>(
            EdgeInsets.symmetric(horizontal: 16.0)),
        leading: const Icon(Icons.search),
        trailing: [
          _searchValue != null
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    setState(() {
                      _searchValue = null;
                      searchBarController.clear();
                      epubPlayerKey.currentState!.clearSearch();
                    });
                  },
                )
              : const SizedBox(),
        ],
        onSubmitted: (value) {
          setState(() {
            if (value.isEmpty) {
              _searchValue = null;
            } else {
              _searchValue = value;
              epubPlayerKey.currentState!.search(value);
            }
          });
        },
      ),
    );
    var searchResult = Expanded(
        child: Column(
      children: [
        const SizedBox(height: 6.0),
        StreamBuilder<double>(
          stream: epubPlayerKey.currentState!.searchProgressStream,
          builder: (context, snapshot) {
            return snapshot.data == 1.0
                ? const SizedBox()
                : LinearProgressIndicator(
                    value: snapshot.data ?? 0.0,
                  );
          },
        ),
        StreamBuilder(
            stream: epubPlayerKey.currentState!.searchResultStream,
            builder: (context, snapshot) {
              if (snapshot.data == null) {
                return const SizedBox();
              }
              List<SearchResultModel> searchResults = snapshot.data!;
              return Expanded(
                child: ListView.builder(
                  itemCount: searchResults.length,
                  itemBuilder: (context, index) {
                    return searchResultWidget(
                      searchResult: searchResults[index],
                      hideAppBarAndBottomBar: widget.hideAppBarAndBottomBar,
                      epubPlayerKey: widget.epubPlayerKey,
                    );
                  },
                ),
              );
            }),
      ],
    ));
    return Column(
      children: [
        searchBox,
        _searchValue != null
            ? searchResult
            : Expanded(
                child: ListView.builder(
                  controller: listViewController,
                  itemCount: widget.tocItems.length,
                  itemBuilder: (context, index) {
                    return TocItemWidget(
                        tocItem: widget.tocItems[index],
                        hideAppBarAndBottomBar: widget.hideAppBarAndBottomBar,
                        epubPlayerKey: widget.epubPlayerKey);
                  },
                ),
              ),
      ],
    );
  }
}

Widget searchResultWidget({
  required SearchResultModel searchResult,
  required Function hideAppBarAndBottomBar,
  required GlobalKey<EpubPlayerState> epubPlayerKey,
}) {
  bool isExpanded = true;
  TextStyle matchStyle = TextStyle(
    color: Theme.of(navigatorKey.currentContext!).colorScheme.primary,
    fontWeight: FontWeight.bold,
  );
  TextStyle prePostStyle = const TextStyle(
    color: Colors.grey,
  );
  return StatefulBuilder(
    builder: (context, setState) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextButton(
            onPressed: () {
              setState(() {
                isExpanded = !isExpanded;
              });
            },
            child: Row(
              children: [
                Flexible(
                    child: Text(searchResult.label,
                        overflow: TextOverflow.ellipsis)),
                isExpanded
                    ? const Icon(Icons.expand_less)
                    : const Icon(Icons.expand_more),
                // const Spacer(),
                Text(
                  searchResult.subitems.length.toString(),
                  style: const TextStyle(color: Colors.grey),
                ),
              ],
            ),
          ),
          if (isExpanded)
            for (var subItem in searchResult.subitems)
              TextButton(
                onPressed: () {
                  hideAppBarAndBottomBar(false);
                  epubPlayerKey.currentState!.goToCfi(subItem.cfi);
                },
                child: RichText(
                  text: TextSpan(
                    children: [
                      TextSpan(text: subItem.pre, style: prePostStyle),
                      TextSpan(text: subItem.match, style: matchStyle),
                      TextSpan(text: subItem.post, style: prePostStyle),
                    ],
                  ),
                ),
              ),
        ],
      );
    },
  );
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
  TocItemWidgetState createState() => TocItemWidgetState();
}

class TocItemWidgetState extends State<TocItemWidget> {
  late bool _isExpanded;

  @override
  void initState() {
    super.initState();
    _isExpanded = _isSelected(widget.tocItem);
  }

  TextStyle tocStyle(content) => TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.onSurface,
      );

  TextStyle tocStyleSelected(context) => TextStyle(
        fontSize: 16,
        color: Theme.of(context).colorScheme.primary,
        fontWeight: FontWeight.bold,
      );

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

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            if (widget.tocItem.subitems.isNotEmpty)
              IconButton(
                icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                onPressed: () {
                  setState(() {
                    _isExpanded = !_isExpanded;
                  });
                },
              ),
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
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      children: [
                        Text(
                          widget.tocItem.label.trim(),
                          style: _isSelected(widget.tocItem)
                              ? tocStyleSelected(context)
                              : tocStyle(context),
                        ),
                      ],
                    ),
                    Text(
                      widget.tocItem.startPage.toString(),
                      style: _isSelected(widget.tocItem)
                          ? tocStyleSelected(context).copyWith(
                              fontSize: 14, fontWeight: FontWeight.w300)
                          : tocStyle(context).copyWith(
                              fontSize: 14, fontWeight: FontWeight.w300),
                    )
                  ],
                ),
              ),
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
            color: Colors.grey.withAlpha(110)),
      ],
    );
  }
}
