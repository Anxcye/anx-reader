import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/sort_field.dart';
import 'package:anx_reader/enums/sort_order.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/get_path/get_temp_dir.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/widgets/bookshelf/book_bottom_sheet.dart';
import 'package:anx_reader/widgets/bookshelf/book_folder.dart';
import 'package:anx_reader/widgets/bookshelf/sync_button.dart';
import 'package:anx_reader/widgets/tips/bookshelf_tips.dart';
import 'package:desktop_drop/desktop_drop.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_reorderable_grid_view/widgets/custom_draggable.dart';
import 'package:flutter_reorderable_grid_view/widgets/reorderable_builder.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:icons_plus/icons_plus.dart';

class BookshelfPage extends ConsumerStatefulWidget {
  const BookshelfPage({super.key,
  this.controller  
  });
  final ScrollController? controller;

  @override
  ConsumerState<BookshelfPage> createState() => BookshelfPageState();
}

class BookshelfPageState extends ConsumerState<BookshelfPage> {
  late final _scrollController = widget.controller ?? ScrollController();
  final _gridViewKey = GlobalKey();
  bool _dragging = false;
  String? _searchValue;
  TextEditingController searchBarController = TextEditingController();

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
    if (!Platform.isAndroid) {
      fileList = await Future.wait(files.map((file) async {
        Directory tempDir = await getAnxTempDir();
        File tempFile = File('${tempDir.path}/${file.name}');
        await File(file.path!).copy(tempFile.path);
        return tempFile;
      }).toList());
    } else {
      fileList = files.map((file) => File(file.path!)).toList();
    }

    importBookList(fileList, context, ref);
  }

  @override
  Widget build(BuildContext context) {
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
                          return book.length == 1
                              ? CustomDraggable(
                                  key: Key(book.first.id.toString()),
                                  data: book.first,
                                  child: BookFolder(books: book))
                              : BookFolder(
                                  key: Key(book.first.id.toString()),
                                  books: book,
                                );
                        },
                      ),
                    ],
                    builder: (children) {
                      return LayoutBuilder(builder: (context, constraints) {
                        return GridView(
                          key: _gridViewKey,
                          controller: _scrollController,
                          padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                          gridDelegate:
                              SliverGridDelegateWithFixedCrossAxisCount(
                            crossAxisCount:
                                constraints.maxWidth ~/ Prefs().bookCoverWidth,
                            childAspectRatio: 1 / 2.1,
                            mainAxisSpacing: 30,
                            crossAxisSpacing: 20,
                          ),
                          children: children,
                        );
                      });
                    });
          },
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, stack) => Center(child: Text(error.toString())),
        );

    Widget body = DropTarget(
      onDragDone: (detail) async {
        List<File> files = [];
        for (var file in detail.files) {
          final tempFilePath = '${(await getAnxTempDir()).path}/${file.name}';
          await File(file.path).copy(tempFilePath);
          files.add(File(tempFilePath));
        }
        importBookList(files, context, ref);
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
    );

    PreferredSizeWidget appBar = AppBar(
      forceMaterialTransparency: true,
      title: Container(
        height: 34,
        constraints: const BoxConstraints(maxWidth: 400),
        child: SearchBar(
          backgroundColor: WidgetStateProperty.all(
              Theme.of(context).colorScheme.primary.withAlpha(5)),
          controller: searchBarController,
          hintText: L10n.of(context).appName,
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
                        ref.read(bookListProvider.notifier).search(null);
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
                ref.read(bookListProvider.notifier).search(value);
              }
            });
          },
        ),
      ),
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
                            child: SegmentedButton(
                              onSelectionChanged: (value) {
                                Prefs().sortOrder = value.first;
                                ref.read(bookListProvider.notifier).refresh();
                                setState(() {});
                              },
                              segments: SortOrderEnum.values
                                  .map((e) => ButtonSegment(
                                        value: e,
                                        label: Text(e.getL10n(
                                            navigatorKey.currentContext!)),
                                      ))
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
