import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/search_result_model.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/providers/book_toc.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookToc extends ConsumerStatefulWidget {
  const BookToc({
    super.key,
    required this.epubPlayerKey,
    required this.hideAppBarAndBottomBar,
  });

  final GlobalKey<EpubPlayerState> epubPlayerKey;
  final Function hideAppBarAndBottomBar;

  @override
  ConsumerState<BookToc> createState() => _BookTocState();
}

class _BookTocState extends ConsumerState<BookToc> {
  String? _searchValue;
  TextEditingController searchBarController = TextEditingController();
  ScrollController listViewController = ScrollController();
  late List<TocItem> tocItems;
  final Map<String, GlobalKey<TocItemWidgetState>> _itemKeys = {};
  String? _lastAutoScrolledHref;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchValue = null;
    searchBarController.clear();
    searchBarController.dispose();
    listViewController.dispose();
    widget.epubPlayerKey.currentState?.clearSearch();
    super.dispose();
  }

  String _keyForItem(TocItem item) => '${item.id}_${item.href}';

  GlobalKey<TocItemWidgetState> _obtainItemKey(TocItem item) {
    final key = _keyForItem(item);
    return _itemKeys.putIfAbsent(key, () => GlobalKey<TocItemWidgetState>());
  }

  void _reconcileItemKeys(List<TocItem> items) {
    final keys = <String>{};

    void collect(TocItem item) {
      keys.add(_keyForItem(item));
      for (final sub in item.subitems) {
        collect(sub);
      }
    }

    for (final item in items) {
      collect(item);
    }

    _itemKeys.removeWhere((key, _) => !keys.contains(key));
  }

  List<TocItem>? _findPath(List<TocItem> items, String href) {
    for (final item in items) {
      if (item.href == href) {
        return [item];
      }
      final nested = _findPath(item.subitems, href);
      if (nested != null) {
        return [item, ...nested];
      }
    }
    return null;
  }

  void _ensureItemVisible(TocItem item, {bool animated = false}) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final key = _keyForItem(item);
      final context = _itemKeys[key]?.currentContext;
      if (context == null) {
        return;
      }
      Scrollable.ensureVisible(
        context,
        duration:
            animated ? const Duration(milliseconds: 250) : Duration.zero,
        alignment: 0.0,
        curve: Curves.easeInOut,
      );
    });
  }

  void _scrollToCurrent({bool animated = false}) {
    final currentHref = widget.epubPlayerKey.currentState?.chapterHref ?? '';
    if (currentHref.isEmpty) {
      return;
    }
    final path = _findPath(tocItems, currentHref);
    if (path == null || path.isEmpty) {
      return;
    }
    _ensureItemVisible(path.last, animated: animated);
  }
  @override
  Widget build(BuildContext context) {
    tocItems = ref.watch(bookTocProvider);
    _reconcileItemKeys(tocItems);

    final currentHref = widget.epubPlayerKey.currentState?.chapterHref ?? '';
    final currentPath = currentHref.isEmpty
        ? <TocItem>[]
        : (_findPath(tocItems, currentHref) ?? <TocItem>[]);

    if (_searchValue == null &&
        currentHref.isNotEmpty &&
        currentHref != _lastAutoScrolledHref &&
        currentPath.isNotEmpty) {
      _lastAutoScrolledHref = currentHref;
      _ensureItemVisible(currentPath.last);
    }

    var locatingButton = IconButton(
      icon: const Icon(Icons.my_location),
      onPressed: () {
        _scrollToCurrent(animated: true);
      },
    );

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
                      widget.epubPlayerKey.currentState!.clearSearch();
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
              widget.epubPlayerKey.currentState!.search(value);
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
    final columnChildren = <Widget>[
      Row(
        children: [
          Expanded(child: searchBox),
          if (_searchValue == null) locatingButton,
        ],
      ),
    ];

    columnChildren.add(
      _searchValue != null
          ? searchResult
          : Expanded(
              child: ListView.builder(
                controller: listViewController,
                itemCount: tocItems.length,
                itemBuilder: (context, index) {
                  final item = tocItems[index];
                  return TocItemWidget(
                    key: _obtainItemKey(item),
                    tocItem: item,
                    hideAppBarAndBottomBar: widget.hideAppBarAndBottomBar,
                    epubPlayerKey: widget.epubPlayerKey,
                    obtainItemKey: _obtainItemKey,
                  );
                },
              ),
            ),
    );
    return Column(children: columnChildren);
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
  final GlobalKey<TocItemWidgetState> Function(TocItem tocItem) obtainItemKey;

  const TocItemWidget(
      {super.key,
      required this.tocItem,
      required this.hideAppBarAndBottomBar,
      required this.epubPlayerKey,
      required this.obtainItemKey});

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

  @override
  void didUpdateWidget(covariant TocItemWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_isSelected(widget.tocItem) && !_isExpanded) {
      _isExpanded = true;
    }
  }

  TextStyle tocStyle(content) => TextStyle(
        fontSize: 15,
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
    bool isEnd = widget.tocItem.subitems.isEmpty && _isSelected(widget.tocItem);
    var current = widget.epubPlayerKey.currentState!.chapterCurrentPage;
    var total = widget.epubPlayerKey.currentState!.chapterTotalPages;

    final progress = '$current / $total';

    return Column(
      children: [
        SizedBox(
          height: isEnd ? 60 : 40,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              if (widget.tocItem.subitems.isNotEmpty)
                IconButton(
                  padding: const EdgeInsets.all(0),
                  icon: Icon(
                    _isExpanded ? Icons.expand_less : Icons.expand_more,
                    size: 32,
                  ),
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
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              widget.tocItem.label.trim(),
                              overflow: TextOverflow.ellipsis,
                              style: _isSelected(widget.tocItem)
                                  ? tocStyleSelected(context)
                                  : tocStyle(context),
                            ),
                            if (isEnd)
                              Padding(
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 10.0),
                                child: Row(
                                  children: [
                                    Icon(Icons.keyboard_arrow_right_rounded),
                                    SizedBox(width: 10),
                                    Text(progress),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        widget.tocItem.percentage,
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
        ),
        if (_isExpanded)
          for (var subItem in widget.tocItem.subitems)
            Padding(
              padding: const EdgeInsets.only(left: 40.0),
              child: TocItemWidget(
                  key: widget.obtainItemKey(subItem),
                  tocItem: subItem,
                  hideAppBarAndBottomBar: widget.hideAppBarAndBottomBar,
                  epubPlayerKey: widget.epubPlayerKey,
                  obtainItemKey: widget.obtainItemKey),
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
