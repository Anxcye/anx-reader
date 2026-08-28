import 'dart:io';
import 'dart:math';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/hint_key.dart';
import 'package:anx_reader/enums/sort_field.dart';
import 'package:anx_reader/enums/sort_order.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/tag.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/providers/book_filters.dart';
import 'package:anx_reader/providers/tags.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/page/search/search_page.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/color/hash_color.dart';
import 'package:anx_reader/utils/platform_utils.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/widgets/bookshelf/book_bottom_sheet.dart';
import 'package:anx_reader/widgets/bookshelf/book_folder.dart';
import 'package:anx_reader/widgets/bookshelf/sync_button.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:anx_reader/widgets/common/tag_chip.dart';
import 'package:anx_reader/widgets/hint/hint_banner.dart';
import 'package:anx_reader/widgets/common/anx_segmented_button.dart';
import 'package:anx_reader/widgets/tips/bookshelf_tips.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/custom_draggable.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:path/path.dart' as p;

class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key, this.controller});
  final ScrollController? controller;

  @override
  ConsumerState<BookshelfPage> createState() => BookshelfPageState();
}

class BookshelfPageState extends ConsumerState<BookshelfPage>
    with AutomaticKeepAliveClientMixin {
  late final _scrollController = widget.controller ?? ScrollController();
  final _gridViewKey = GlobalKey();
  bool _dragging = false;
  final GlobalKey _tagButtonKey = GlobalKey();
  final TextEditingController _editTagController = TextEditingController();

  @override
  bool get wantKeepAlive => true;

  @override
  void dispose() {
    _editTagController.dispose();
    super.dispose();
  }

  Future<File> _copyToTempFile({
    required String sourcePath,
    required String fileName,
  }) async {
    final tempDir = await getAnxTempDir();
    final targetPath = p.join(tempDir.path, fileName);
    final targetFile = File(targetPath);
    if (await targetFile.exists()) {
      await targetFile.delete();
    }
    return File(sourcePath).copy(targetPath);
  }

  Future<void> _importBook() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.any,
      allowMultiple: true,
    );

    if (result == null) {
      return;
    }

    List<PlatformFile> files = result.files;
    AnxLog.info('importBook files: ${files.toString()}');
    List<File> fileList = [];
    // FilePicker on Windows will return files with original path,
    // but on Android it will return files with temporary path.
    // So we need to save the files to the temp directory.
    if (!AnxPlatform.isAndroid) {
      fileList = await Future.wait(files.map((file) async {
        return _copyToTempFile(sourcePath: file.path!, fileName: file.name);
      }).toList());
    } else {
      fileList = files.map((file) => File(file.path!)).toList();
    }

    if (!mounted) return;
    importBookList(fileList, context, ref);
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final statusFilter = ref.watch(readingStatusFilterNotifierProvider);
    final selectedTags = ref.watch(tagSelectionProvider);
    final tagsAsync = ref.watch(tagListProvider);

    Widget buildFilterBar() {
      final statusChips = [
        _StatusChip(
          label: L10n.of(context).bookshelfFilterFinished,
          selected: statusFilter == ReadingStatusFilter.finished,
          onTap: () {
            ref
                .read(readingStatusFilterNotifierProvider.notifier)
                .toggle(ReadingStatusFilter.finished);
            ref.read(bookListProvider.notifier).refresh();
          },
        ),
        _StatusChip(
          label: L10n.of(context).bookshelfFilterReading,
          selected: statusFilter == ReadingStatusFilter.reading,
          onTap: () {
            ref
                .read(readingStatusFilterNotifierProvider.notifier)
                .toggle(ReadingStatusFilter.reading);
            ref.read(bookListProvider.notifier).refresh();
          },
        ),
        _StatusChip(
          label: L10n.of(context).bookshelfFilterNotStarted,
          selected: statusFilter == ReadingStatusFilter.notStarted,
          onTap: () {
            ref
                .read(readingStatusFilterNotifierProvider.notifier)
                .toggle(ReadingStatusFilter.notStarted);
            ref.read(bookListProvider.notifier).refresh();
          },
        ),
      ];

      Future<void> showTagEditDialog(Tag tag) async {
        await TagChip.showEditDialog(
          context: context,
          initialName: tag.name,
          initialColor: tag.color ?? hashColor(tag.name),
          onRename: (newName) async {
            await ref
                .read(tagListProvider.notifier)
                .updateTag(tag.id, newName: newName);
            ref.read(bookListProvider.notifier).refresh();
          },
          onColorChange: (color) async {
            await ref
                .read(tagListProvider.notifier)
                .updateTag(tag.id, color: color);
            ref.read(bookListProvider.notifier).refresh();
          },
          onDelete: () async {
            await ref.read(tagListProvider.notifier).deleteTag(tag.id);
            if (selectedTags.contains(tag.id)) {
              ref.read(tagSelectionProvider.notifier).toggle(tag.id);
            }
            ref.read(bookListProvider.notifier).refresh();
          },
        );
      }

      Future<void> showTagMenu() async {
        final tags = tagsAsync.when(
          data: (value) => value,
          loading: () => const <Tag>[],
          error: (_, __) => const <Tag>[],
        );

        if (!context.mounted) return;

        final renderBox =
            _tagButtonKey.currentContext?.findRenderObject() as RenderBox?;
        final overlay =
            Overlay.of(context).context.findRenderObject() as RenderBox?;
        if (renderBox == null || overlay == null) return;

        final position = RelativeRect.fromRect(
          Rect.fromPoints(
            renderBox.localToGlobal(Offset.zero, ancestor: overlay),
            renderBox.localToGlobal(
              renderBox.size.bottomRight(Offset.zero),
              ancestor: overlay,
            ),
          ),
          Offset.zero & overlay.size,
        );

        final liveSelected = {...selectedTags};

        final boxMaxWidth = max(MediaQuery.of(context).size.width * 0.8, 500.0);

        await showMenu<int>(
          color: Colors.transparent,
          shadowColor: Colors.transparent,
          context: context,
          position: position,
          constraints: BoxConstraints(maxHeight: 360, maxWidth: boxMaxWidth),
          items: [
            PopupMenuItem<int>(
              enabled: false,
              padding: EdgeInsets.zero,
              child: Align(
                alignment: Alignment.topRight,
                child: FilledContainer(
                  constraints:
                      BoxConstraints(maxHeight: 340, maxWidth: boxMaxWidth),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                  child: StatefulBuilder(
                    builder: (context, setStateMenu) {
                      return SingleChildScrollView(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: [
                            if (tags.isEmpty)
                              Text(
                                L10n.of(context).tagsEmptyHint,
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            // "No tag" virtual option - only show when there are tags
                            if (tags.isNotEmpty)
                              TagChip(
                                label: L10n.of(context).noTagFilter,
                                color: Colors.grey,
                                selected: liveSelected.contains(kNoTagFilterId),
                                onTap: () {
                                  setStateMenu(() {
                                    if (liveSelected.contains(kNoTagFilterId)) {
                                      liveSelected.remove(kNoTagFilterId);
                                    } else {
                                      // Mutual exclusion: clear other tags when selecting "no tag"
                                      liveSelected.clear();
                                      liveSelected.add(kNoTagFilterId);
                                    }
                                  });
                                  ref
                                      .read(tagSelectionProvider.notifier)
                                      .toggle(kNoTagFilterId);
                                  ref.read(bookListProvider.notifier).refresh();
                                },
                                dense: false,
                              ),
                            for (final tag in tags)
                              TagChip(
                                label: tag.name,
                                color: tag.color,
                                selected: liveSelected.contains(tag.id),
                                onTap: () {
                                  setStateMenu(() {
                                    if (liveSelected.contains(tag.id)) {
                                      liveSelected.remove(tag.id);
                                    } else {
                                      // Mutual exclusion: clear "no tag" when selecting a regular tag
                                      liveSelected.remove(kNoTagFilterId);
                                      liveSelected.add(tag.id);
                                    }
                                  });
                                  ref
                                      .read(tagSelectionProvider.notifier)
                                      .toggle(tag.id);
                                  ref.read(bookListProvider.notifier).refresh();
                                },
                                onLongPress: () {
                                  Navigator.of(context).pop();
                                  Future.microtask(
                                      () => showTagEditDialog(tag));
                                },
                                dense: false,
                              ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      }

      final selectedTagWidgets = tagsAsync.when(
        data: (tags) {
          final tagMap = {for (final t in tags) t.id: t};
          final List<Widget> chips = [];

          // Display "no tag" chip
          if (selectedTags.contains(kNoTagFilterId)) {
            chips.add(Padding(
              padding: const EdgeInsets.only(left: 8),
              child: TagChip(
                label: L10n.of(context).noTagFilter,
                color: Colors.grey,
                selected: true,
                onTap: () {
                  ref
                      .read(tagSelectionProvider.notifier)
                      .toggle(kNoTagFilterId);
                  ref.read(bookListProvider.notifier).refresh();
                },
                dense: true,
              ),
            ));
          }

          // Display regular tag chips
          chips.addAll(selectedTags
              .where((id) => id != kNoTagFilterId)
              .map((id) => tagMap[id])
              .whereType<Tag>()
              .map((tag) => Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: TagChip(
                      label: tag.name,
                      color: tag.color,
                      selected: true,
                      onTap: () {
                        ref.read(tagSelectionProvider.notifier).toggle(tag.id);
                        ref.read(bookListProvider.notifier).refresh();
                      },
                      dense: true,
                    ),
                  )));

          return Row(children: chips);
        },
        loading: () => const SizedBox.shrink(),
        error: (_, __) => const SizedBox.shrink(),
      );

      return Container(
        height: 40,
        padding: const EdgeInsets.fromLTRB(12, 0, 12, 5),
        child: Row(
          children: [
            const SizedBox(width: 8),
            Expanded(
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ...statusChips,
                    selectedTagWidgets,
                  ],
                ),
              ),
            ),
            IconButton(
              key: _tagButtonKey,
              icon: const Icon(EvaIcons.pricetags_outline, size: 22),
              tooltip: L10n.of(context).bookshelfFilterTagsTooltip,
              onPressed: showTagMenu,
            ),
          ],
        ),
      );
    }

    void handleBottomSheet(BuildContext context, Book book) {
      showBottomSheet(
        context: context,
        builder: (context) => BookBottomSheet(book: book),
      );
    }

    List<int> lockedIndices = [];

    Widget buildBookshelfBody = ref.watch(bookListProvider).when(
          data: (books) {
            for (int i = 0; i < books.length; i++) {
              // folder can't be dragged
              if (books[i].length != 1) {
                lockedIndices.add(i);
              }
            }
            return books.isEmpty
                ? const Center(child: BookshelfTips())
                : ReorderableBuilder(
                    // lock all index of books
                    lockedIndices: lockedIndices,
                    enableDraggable: true,
                    longPressDelay: const Duration(milliseconds: 300),
                    onReorder: (ReorderedListFunction reorderedListFunction) {},
                    scrollController: _scrollController,
                    onDragStarted: (index) {
                      if (books[index].length == 1) {
                        handleBottomSheet(context, books[index].first);
                        // add other books to lockedIndices
                        for (int i = 0; i < books.length; i++) {
                          if (i != index) {
                            lockedIndices.add(i);
                          }
                        }
                      }
                    },
                    onDragEnd: (index) {
                      // remove all books from lockedIndices
                      lockedIndices = [];
                      for (int i = 0; i < books.length; i++) {
                        if (books[i].length != 1) {
                          lockedIndices.add(i);
                        }
                      }
                      setState(() {});
                    },
                    children: [
                      ...books.map(
                        (book) {
                          final topLevelKey = ValueKey<String>(
                            book.first.id.toString(),
                          );
                          return book.length == 1
                              ? CustomDraggable(
                                  key: topLevelKey,
                                  data: book.first,
                                  child: BookFolder(books: book),
                                )
                              : BookFolder(
                                  key: topLevelKey,
                                  books: book,
                                );
                        },
                      ),
                    ],
                    builder: (children) {
                      return LayoutBuilder(builder: (context, constraints) {
                        return Column(
                          children: [
                            HintBanner(
                                icon: const Icon(Icons.copy),
                                hintKey: HintKey.dragAndDropToCreateFolder,
                                margin: EdgeInsets.fromLTRB(20, 0, 20, 5),
                                child: Text(L10n.of(context)
                                    .dragAndDropToCreateFolderHint)),
                            Expanded(
                              child: GridView(
                                key: _gridViewKey,
                                controller: _scrollController,
                                padding:
                                    const EdgeInsets.fromLTRB(20, 12, 20, 80),
                                gridDelegate:
                                    SliverGridDelegateWithFixedCrossAxisCount(
                                  crossAxisCount: constraints.maxWidth ~/
                                      Prefs().bookCoverWidth,
                                  childAspectRatio: 1 / 2.1,
                                  mainAxisSpacing: 30,
                                  crossAxisSpacing: 20,
                                ),
                                children: children,
                              ),
                            ),
                          ],
                        );
                      });
                    });
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(error.toString())),
        );

    Widget body = Column(
      children: [
        buildFilterBar(),
        Expanded(
          child: DropTarget(
            onDragDone: (detail) async {
              List<File> files = [];
              for (var file in detail.files) {
                files.add(await _copyToTempFile(
                  sourcePath: file.path,
                  fileName: file.name,
                ));
              }
              if (!mounted) return;
              final rootContext = navigatorKey.currentContext;
              if (rootContext == null || !rootContext.mounted) return;
              importBookList(files, rootContext, ref);
              setState(() {
                _dragging = false;
              });
            },
            onDragEntered: (detail) {
              setState(() {
                _dragging = true;
              });
            },
            onDragExited: (detail) {
              setState(() {
                _dragging = false;
              });
            },
            child: Stack(
              children: [
                buildBookshelfBody,
                if (_dragging)
                  Container(
                    color: Theme.of(context).colorScheme.surface.withAlpha(90),
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            EvaIcons.arrowhead_down_outline,
                            size: 48,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                          Text(
                            L10n.of(context).bookshelfDragging,
                            style: Theme.of(context).textTheme.titleMedium,
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ],
    );

    PreferredSizeWidget appBar = AppBar(
      forceMaterialTransparency: true,
      title: Container(
          height: 34,
          constraints: const BoxConstraints(maxWidth: 400),
          child: InkWell(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) => const SearchPage(),
                ),
              );
            },
            child: FilledContainer(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              color: Theme.of(context).colorScheme.surface.withAlpha(80),
              child: Row(
                children: [
                  const Icon(Icons.search, color: Colors.grey),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(L10n.of(context).searchBooksOrNotes,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: Theme.of(context).hintColor),
                        overflow: TextOverflow.ellipsis),
                  )
                ],
              ),
            ),
          )),
      actions: [
        const SyncButton(),
        IconButton(
          icon: const Icon(Icons.add),
          onPressed: _importBook,
        ),
        IconButton(
            icon: const Icon(Icons.sort),
            onPressed: () {
              showMenu(
                context: context,
                position: RelativeRect.fromLTRB(
                  MediaQuery.of(context).size.width,
                  MediaQuery.of(context).padding.top + kToolbarHeight,
                  0.0,
                  0.0,
                ),
                items: [
                  for (var sortField in SortFieldEnum.values)
                    PopupMenuItem(
                        child: Text(
                          sortField.getL10n(context),
                          style: TextStyle(
                            color: sortField == Prefs().sortField
                                ? Theme.of(context).colorScheme.primary
                                : Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        onTap: () {
                          Prefs().sortField = sortField;
                          ref.read(bookListProvider.notifier).refresh();
                        }),
                  PopupMenuItem(
                    enabled: false,
                    child: StatefulBuilder(builder: (_, setState) {
                      return Row(
                        children: [
                          Expanded(
                            child: AnxSegmentedButton<SortOrderEnum>(
                              onSelectionChanged: (value) {
                                Prefs().sortOrder = value.first;
                                ref.read(bookListProvider.notifier).refresh();
                                setState(() {});
                              },
                              segments: SortOrderEnum.values
                                  .map(
                                    (e) => SegmentButtonItem(
                                      value: e,
                                      label: e.getL10n(
                                          navigatorKey.currentContext!),
                                    ),
                                  )
                                  .toList(),
                              selected: {Prefs().sortOrder},
                            ),
                          ),
                        ],
                      );
                    }),
                  )
                ],
              );
            }),
      ],
    );

    return Container(
        decoration: Prefs().eInkMode
            ? null
            : BoxDecoration(
                gradient: RadialGradient(
                  tileMode: TileMode.clamp,
                  center: Alignment.topRight,
                  radius: 1,
                  colors: [
                    Theme.of(context).colorScheme.primary.withAlpha(5),
                    Theme.of(context).scaffoldBackgroundColor,
                  ],
                ),
              ),
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: appBar,
          body: body,
        ));
  }
}

class _StatusChip extends StatelessWidget {
  const _StatusChip({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        labelPadding: const EdgeInsets.all(0),
        padding: const EdgeInsets.symmetric(horizontal: 4),
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: Theme.of(context).colorScheme.secondaryContainer,
        checkmarkColor: Theme.of(context).colorScheme.primary,
      ),
    );
  }
}
