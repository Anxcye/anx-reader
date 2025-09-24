import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/search_result_model.dart';
import 'package:anx_reader/models/toc_item.dart';
import 'package:anx_reader/page/book_player/epub_player.dart';
import 'package:anx_reader/providers/book_toc.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_sticky_header/flutter_sticky_header.dart';

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
  static const double _headerExtent = 60;
  static const double _entryExtent = 60;

  String? _searchValue;
  final TextEditingController searchBarController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final Map<String, GlobalKey> _sectionHeaderKeys = {};
  final Set<String> _expandedIds = <String>{};
  List<_TocGroup> _groups = const [];
  _TocTarget? _currentTarget;
  String? _lastAutoScrollHref;
  bool _expansionInitialized = false;

  GlobalKey<EpubPlayerState> get epubPlayerKey => widget.epubPlayerKey;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _searchValue = null;
    searchBarController.dispose();
    _scrollController.dispose();
    epubPlayerKey.currentState?.clearSearch();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final tocItems = ref.watch(bookTocProvider);
    _initializeExpansionIfNeeded(tocItems);
    _groups = _composeGroups(tocItems);
    _currentTarget = _resolveCurrentTarget();
    _ensureExpandedForCurrentTarget();

    final currentHref =
        _currentTarget == null ? null : _hrefForTarget(_currentTarget!);
    if (_searchValue == null &&
        currentHref != null &&
        currentHref != _lastAutoScrollHref) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentChapter(animated: false);
      });
    }

    var locatingButton = IconButton(
      icon: const Icon(Icons.my_location),
      onPressed: () {
        _scrollToCurrentChapter();
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
        Row(
          children: [
            Expanded(child: searchBox),
            if (_searchValue == null) locatingButton,
          ],
        ),
        _searchValue != null
            ? searchResult
            : Expanded(
                child: CustomScrollView(
                  controller: _scrollController,
                  slivers: [
                    const SliverToBoxAdapter(child: SizedBox(height: 4)),
                    ..._buildTocSlivers(),
                    const SliverPadding(
                      padding: EdgeInsets.only(bottom: 16),
                      sliver: SliverToBoxAdapter(child: SizedBox(height: 8)),
                    ),
                  ],
                ),
              ),
      ],
    );
  }

  List<_TocGroup> _composeGroups(List<TocItem> roots) {
    return roots
        .map((root) => _TocGroup(
              root: root,
              entries: _flattenItems(
                root.subitems,
                depth: 1,
                ancestors: [root.id],
              ),
            ))
        .toList(growable: false);
  }

  List<_FlattenedTocEntry> _flattenItems(
    List<TocItem> items, {
    required int depth,
    required List<String> ancestors,
  }) {
    final result = <_FlattenedTocEntry>[];
    for (final item in items) {
      final entry = _FlattenedTocEntry(
        item: item,
        depth: depth,
        ancestors: List<String>.from(ancestors),
        hasChildren: item.subitems.isNotEmpty,
      );
      result.add(entry);
      if (item.subitems.isNotEmpty) {
        result.addAll(
          _flattenItems(
            item.subitems,
            depth: depth + 1,
            ancestors: [...ancestors, item.id],
          ),
        );
      }
    }
    return result;
  }

  List<Widget> _buildTocSlivers() {
    final slivers = <Widget>[];
    final selectedHref = epubPlayerKey.currentState?.chapterHref;
    final currentPage = epubPlayerKey.currentState?.chapterCurrentPage ?? 0;
    final totalPage = epubPlayerKey.currentState?.chapterTotalPages ?? 0;

    for (int groupIndex = 0; groupIndex < _groups.length; groupIndex++) {
      final group = _groups[groupIndex];
      final headerKey = _sectionHeaderKeyFor(group.root.id);
      final isHeaderSelected = group.root.href == selectedHref;
      final bool headerExpanded = _expandedIds.contains(group.root.id);
      final visibleEntries = headerExpanded
          ? _visibleEntriesForGroup(group)
          : const <_FlattenedTocEntry>[];
      final sliver = visibleEntries.isEmpty
          ? const SliverToBoxAdapter(child: SizedBox(height: 0))
          : SliverFixedExtentList(
              itemExtent: _entryExtent,
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final entry = visibleEntries[index];
                  final item = entry.item;
                  final isSelected = item.href == selectedHref;
                  return _TocEntryTile(
                    item: item,
                    depth: entry.depth,
                    isSelected: isSelected,
                    hasChildren: entry.hasChildren,
                    isExpanded: _expandedIds.contains(item.id),
                    showProgress: isSelected && item.subitems.isEmpty,
                    progressText:
                        isSelected ? '$currentPage / $totalPage' : null,
                    onToggleExpand: entry.hasChildren
                        ? () {
                            setState(() {
                              if (_expandedIds.contains(item.id)) {
                                _expandedIds.remove(item.id);
                              } else {
                                _expandedIds.add(item.id);
                              }
                            });
                          }
                        : null,
                    onTap: () {
                      widget.hideAppBarAndBottomBar(false);
                      epubPlayerKey.currentState?.goToHref(item.href);
                    },
                  );
                },
                childCount: visibleEntries.length,
              ),
            );

      slivers.add(
        SliverStickyHeader.builder(
          builder: (context, state) => KeyedSubtree(
            key: headerKey,
            child: _TocHeader(
              item: group.root,
              isPinned: state.isPinned,
              scrollPercentage: state.scrollPercentage,
              isSelected: isHeaderSelected,
              isExpanded: headerExpanded,
              onToggleExpand: () {
                setState(() {
                  if (headerExpanded) {
                    _expandedIds.remove(group.root.id);
                  } else {
                    _expandedIds.add(group.root.id);
                  }
                });
              },
              progressText:
                  isHeaderSelected ? '$currentPage / $totalPage' : null,
              onTap: () {
                widget.hideAppBarAndBottomBar(false);
                epubPlayerKey.currentState?.goToHref(group.root.href);
              },
            ),
          ),
          sliver: SliverMainAxisGroup(
            slivers: [
              sliver,
            ],
          ),
        ),
      );
    }

    return slivers;
  }

  _TocTarget? _resolveCurrentTarget() {
    final currentHref = epubPlayerKey.currentState?.chapterHref;
    if (currentHref == null) return null;
    for (int groupIndex = 0; groupIndex < _groups.length; groupIndex++) {
      final group = _groups[groupIndex];
      if (group.root.href == currentHref) {
        return _TocTarget(groupIndex: groupIndex, entryIndex: -1);
      }
      for (int entryIndex = 0;
          entryIndex < group.entries.length;
          entryIndex++) {
        if (group.entries[entryIndex].item.href == currentHref) {
          return _TocTarget(groupIndex: groupIndex, entryIndex: entryIndex);
        }
      }
    }
    return null;
  }

  void _initializeExpansionIfNeeded(List<TocItem> roots) {
    if (_expansionInitialized) return;
    for (final root in roots) {
      _expandedIds.add(root.id);
    }
    _expansionInitialized = true;
  }

  bool _ensureExpandedForCurrentTarget() {
    if (_currentTarget == null) return false;
    final target = _currentTarget!;
    final group = _groups[target.groupIndex];
    bool changed = _expandedIds.add(group.root.id);
    if (target.entryIndex >= 0) {
      final entry = group.entries[target.entryIndex];
      for (final ancestorId in entry.ancestors) {
        if (_expandedIds.add(ancestorId)) {
          changed = true;
        }
      }
    }
    return changed;
  }

  List<_FlattenedTocEntry> _visibleEntriesForGroup(_TocGroup group) {
    return group.entries
        .where((entry) => entry.ancestors
            .every((ancestor) => _expandedIds.contains(ancestor)))
        .toList(growable: false);
  }

  String _hrefForTarget(_TocTarget target) {
    final group = _groups[target.groupIndex];
    if (target.entryIndex < 0) {
      return group.root.href;
    }
    return group.entries[target.entryIndex].item.href;
  }

  void _scrollToCurrentChapter({bool animated = true}) {
    if (!_scrollController.hasClients) return;
    if (_currentTarget == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('未能定位到当前章节')),
      );
      return;
    }

    final target = _currentTarget!;
    final headerKey = _sectionHeaderKeyFor(_groups[target.groupIndex].root.id);
    final headerContext = headerKey.currentContext;
    if (headerContext == null) {
      return;
    }

    final renderObject = headerContext.findRenderObject();
    if (renderObject == null) return;
    final viewport = RenderAbstractViewport.of(renderObject);

    final bool expansionChanged = _ensureExpandedForCurrentTarget();
    if (expansionChanged) {
      setState(() {});
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _scrollToCurrentChapter(animated: animated);
      });
      return;
    }

    double targetOffset = viewport.getOffsetToReveal(renderObject, 0).offset;
    final visibleEntries = _visibleEntriesForGroup(_groups[target.groupIndex]);
    if (target.entryIndex >= 0) {
      final entry = _groups[target.groupIndex].entries[target.entryIndex];
      final visibleIndex = visibleEntries
          .indexWhere((element) => element.item.id == entry.item.id);
      if (visibleIndex == -1) return;
      targetOffset += _headerExtent + visibleIndex * _entryExtent;
    }

    final minExtent = _scrollController.position.minScrollExtent;
    final maxExtent = _scrollController.position.maxScrollExtent;
    targetOffset = targetOffset.clamp(minExtent, maxExtent);

    if (animated) {
      _scrollController.animateTo(
        targetOffset,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeOutCubic,
      );
    } else {
      _scrollController.jumpTo(targetOffset);
    }

    _lastAutoScrollHref = _hrefForTarget(target);
  }

  GlobalKey _sectionHeaderKeyFor(String id) {
    return _sectionHeaderKeys.putIfAbsent(id, () => GlobalKey());
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

class _TocHeader extends StatelessWidget {
  const _TocHeader({
    required this.item,
    required this.isPinned,
    required this.scrollPercentage,
    required this.isSelected,
    required this.isExpanded,
    required this.onToggleExpand,
    required this.onTap,
    this.progressText,
  });

  final TocItem item;
  final bool isPinned;
  final double scrollPercentage;
  final bool isSelected;
  final bool isExpanded;
  final VoidCallback onToggleExpand;
  final VoidCallback onTap;
  final String? progressText;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final Color background = cs.surfaceContainerLow;
    final titleStyle = isSelected
        ? theme.textTheme.titleMedium?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          )
        : theme.textTheme.titleMedium;

    return Material(
      color: background,
      child: SizedBox(
        height: _BookTocState._headerExtent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Row(
              children: [
                if (item.hasChildren)
                IconButton(
                  onPressed: onToggleExpand,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.primary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.label.trim(),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: titleStyle,
                      ),
                      if (progressText != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            progressText!,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: cs.primary,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  item.percentage,
                  style: theme.textTheme.labelLarge?.copyWith(
                    color: isSelected ? cs.primary : cs.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TocEntryTile extends StatelessWidget {
  const _TocEntryTile({
    required this.item,
    required this.depth,
    required this.isSelected,
    required this.hasChildren,
    required this.isExpanded,
    required this.onTap,
    this.showProgress = false,
    this.progressText,
    this.onToggleExpand,
  });

  final TocItem item;
  final int depth;
  final bool isSelected;
  final bool hasChildren;
  final bool isExpanded;
  final VoidCallback onTap;
  final bool showProgress;
  final String? progressText;
  final VoidCallback? onToggleExpand;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;
    final double indent = 16.0 + (depth - 1) * 16.0;
    final titleStyle = isSelected
        ? theme.textTheme.bodyLarge?.copyWith(
            color: cs.primary,
            fontWeight: FontWeight.bold,
          )
        : theme.textTheme.bodyLarge;

    return Material(
      color: isSelected
          ? cs.primaryContainer.withOpacity(0.35)
          : Colors.transparent,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: EdgeInsets.only(left: indent, right: 16),
          child: Row(
            children: [
              if (hasChildren)
                IconButton(
                  onPressed: onToggleExpand,
                  iconSize: 20,
                  padding: EdgeInsets.zero,
                  constraints:
                      const BoxConstraints(minWidth: 32, minHeight: 32),
                  icon: Icon(
                    isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: cs.primary,
                  ),
                )
              else
                const SizedBox(width: 32),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.label.trim(),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: titleStyle,
                    ),
                    if (showProgress && progressText != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Row(
                          children: [
                            Icon(
                              Icons.keyboard_arrow_right_rounded,
                              size: 16,
                              color: cs.primary,
                            ),
                            const SizedBox(width: 4),
                            Text(
                              progressText!,
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: cs.primary,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Text(
                item.percentage,
                style: theme.textTheme.labelMedium?.copyWith(
                  color: isSelected ? cs.primary : cs.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TocGroup {
  const _TocGroup({required this.root, required this.entries});

  final TocItem root;
  final List<_FlattenedTocEntry> entries;
}

class _FlattenedTocEntry {
  const _FlattenedTocEntry(
      {required this.item,
      required this.depth,
      required this.ancestors,
      required this.hasChildren});

  final TocItem item;
  final int depth;
  final List<String> ancestors;
  final bool hasChildren;
}

class _TocTarget {
  const _TocTarget({required this.groupIndex, required this.entryIndex});

  final int groupIndex;
  final int entryIndex; // header -> -1
}
