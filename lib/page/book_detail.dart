import 'dart:io';
import 'dart:ui';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/enums/sync_direction.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/providers/sync.dart';
import 'package:anx_reader/providers/book_list.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/date/convert_seconds.dart';
import 'package:anx_reader/utils/get_path/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/highlight_digit.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class BookDetail extends ConsumerStatefulWidget {
  const BookDetail({super.key, required this.book});

  final Book book;

  @override
  ConsumerState<BookDetail> createState() => _BookDetailState();
}

class _BookDetailState extends ConsumerState<BookDetail> {
  late double rating;
  bool isEditing = false;
  late Book _book;
  bool _isCollapsed = false;

  @override
  void initState() {
    super.initState();
    rating = widget.book.rating;
    _book = widget.book;
  }

  @override
  Widget build(BuildContext context) {
    Widget buildBackground() {
      var bg = Scaffold(
        body: ShaderMask(
          shaderCallback: (rect) {
            return LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Theme.of(context).colorScheme.surface.withAlpha(200),
                Theme.of(context).colorScheme.surface.withAlpha(10),
                Theme.of(context).colorScheme.surface.withAlpha(10),
                // Colors.transparent,
              ],
            ).createShader(
              Rect.fromLTRB(0, 0, rect.width, rect.height),
            );
          },
          blendMode: BlendMode.dstATop,
          child: bookCover(
            context,
            _book,
            height: MediaQuery.of(context).size.height * 0.8,
            width: MediaQuery.of(context).size.width,
          ),
        ),
      );
      return Stack(
        children: [
          bg,
          BackdropFilter(
            filter: ImageFilter.blur(sigmaY: 40, sigmaX: 40),
            child: Container(
              color: Colors.black12,
            ),
          )
        ],
      );
    }

    Widget buildBookBaseDetail(double width) {
      TextStyle bookTitleStyle = TextStyle(
        fontSize: 24,
        fontFamily: 'SourceHanSerif',
        fontWeight: FontWeight.bold,
        color: Theme.of(context).textTheme.bodyLarge!.color,
      );
      TextStyle bookAuthorStyle = TextStyle(
        fontSize: 15,
        fontFamily: 'SourceHanSerif',
        color: Theme.of(context).textTheme.bodyLarge!.color,
      );
      double top = 60;

      return SizedBox(
        height: 270 + top,
        child: Stack(
          children: [
            // background card
            Positioned(
              left: 0,
              top: 150 + top,
              child: SizedBox(
                  height: 120,
                  width: width,
                  child: Card(
                    child: Row(
                      children: [
                        const Spacer(),
                        // progress ring
                        Stack(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(20),
                              width: 100,
                              height: 100,
                              child: CircularProgressIndicator(
                                value: widget.book.readingPercentage,
                                strokeWidth: 6,
                                backgroundColor: Colors.grey[400],
                                valueColor: AlwaysStoppedAnimation<Color>(
                                    Theme.of(context).colorScheme.primary),
                              ),
                            ),
                            Positioned.fill(
                              child: Center(
                                child: Text(
                                  "${(widget.book.readingPercentage * 100).toStringAsFixed(0)}%",
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )),
            ),
            // book cover
            Positioned(
              left: 20,
              top: 0 + top,
              child: GestureDetector(
                onTap: () async {
                  if (!isEditing) {
                    return;
                  }

                  FilePickerResult? result =
                      await FilePicker.platform.pickFiles(
                    type: FileType.image,
                    allowMultiple: false,
                  );

                  if (result == null) {
                    return;
                  }

                  File image = File(result.files.single.path!);

                  AnxLog.info('BookDetail: Image path: ${image.path}');
                  // Delete the existing cover image file
                  final File oldCoverImageFile =
                      File(widget.book.coverFullPath);
                  if (await oldCoverImageFile.exists()) {
                    await oldCoverImageFile.delete();
                  }

                  String oldName = widget.book.coverPath
                      .split('-')
                      .sublist(0, widget.book.coverPath.split('-').length - 1)
                      .join('');
                  if (!oldName.startsWith('cover/')) {
                    oldName = 'cover/$oldName';
                  }

                  String newPath =
                      '$oldName-${DateTime.now().millisecondsSinceEpoch.toString()}.png'
                          .trim();

                  AnxLog.info('BookDetail: New path: $newPath');
                  String newFullPath = getBasePath(newPath);

                  final File newCoverImageFile = File(newFullPath);
                  await newCoverImageFile
                      .writeAsBytes(await image.readAsBytes());
                  widget.book.coverPath = newPath;

                  setState(() {
                    widget.book.coverPath = newPath;
                    updateBook(widget.book);
                    Sync().syncData(SyncDirection.upload, ref);
                    ref.read(bookListProvider.notifier).refresh();
                  });
                },
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      // Set the shadow
                      BoxShadow(
                        color: Colors.grey.withAlpha(128),
                        spreadRadius: 6,
                        blurRadius: 30,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),
                  child: Hero(
                    tag: widget.book.coverFullPath,
                    child: bookCover(context, widget.book,
                        height: 230, width: 160),
                  ),
                ),
              ),
            ),
            // rating bar
            Positioned(
              left: 30,
              top: 240 + top,
              child: RatingBar.builder(
                initialRating: rating,
                minRating: 0,
                direction: Axis.horizontal,
                allowHalfRating: true,
                itemCount: 5,
                itemSize: 20,
                itemPadding: const EdgeInsets.symmetric(horizontal: 4.0),
                itemBuilder: (context, _) => const Icon(
                  Icons.star,
                  color: Colors.amber,
                ),
                onRatingUpdate: (rating) {
                  setState(() {
                    this.rating = rating;
                    updateBookRating(widget.book, rating);
                  });
                },
              ),
            ),
            // book title and author
            Positioned(
              left: 190,
              top: 5 + top,
              child: SizedBox(
                width: width - 190,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextFormField(
                      autofocus: true,
                      initialValue: widget.book.title,
                      enabled: isEditing,
                      style: bookTitleStyle,
                      maxLines: null,
                      minLines: 1,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      onChanged: (value) {
                        widget.book.title = value.replaceAll('\n', ' ');
                      },
                    ),
                    const SizedBox(height: 5),
                    TextFormField(
                      initialValue: widget.book.author,
                      enabled: isEditing,
                      style: bookAuthorStyle,
                      maxLines: null,
                      minLines: 1,
                      decoration: const InputDecoration(
                        border: InputBorder.none,
                        isCollapsed: true,
                      ),
                      onChanged: (value) {
                        widget.book.author = value;
                      },
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    Widget buildEditButton() {
      return Row(
        children: [
          const Spacer(),
          isEditing
              ? OutlinedButton(
                  child: Row(
                    children: [
                      const Icon(Icons.save),
                      const SizedBox(width: 5),
                      Text(L10n.of(context).book_detail_save),
                    ],
                  ),
                  onPressed: () {
                    setState(() {
                      isEditing = false;
                      updateBook(widget.book);
                      Sync().syncData(SyncDirection.upload, ref);
                      ref.read(bookListProvider.notifier).refresh();
                    });
                  },
                )
              : OutlinedButton(
                  child: Row(
                    children: [
                      const Icon(Icons.edit),
                      const SizedBox(width: 5),
                      Text(L10n.of(context).book_detail_edit),
                    ],
                  ),
                  onPressed: () {
                    setState(() {
                      isEditing = true;
                    });
                  }),
        ],
      );
    }

    Widget buildBookStatistics() {
      Widget buildNthBooksItem() {
        TextStyle textStyle = const TextStyle(
          fontSize: 15,
          color: Colors.grey,
        );
        TextStyle digitStyle = const TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
        );

        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: highlightDigit(
              context,
              L10n.of(context).book_detail_nth_book(widget.book.id),
              textStyle,
              digitStyle),
        );
      }

      Widget buildRankItem() {
        return Padding(
          padding: const EdgeInsets.only(left: 20, right: 20),
          child: RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: rating.toString(),
                  style: TextStyle(
                    fontSize: 30,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).textTheme.bodyLarge!.color,
                  ),
                ),
                const TextSpan(
                  text: ' / 5',
                  style: TextStyle(
                    fontSize: 15,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
        );
      }

      Widget buildReadingTimeItem() {
        TextStyle digitStyle = TextStyle(
          fontSize: 30,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).textTheme.bodyLarge!.color,
        );
        TextStyle textStyle = const TextStyle(
          fontSize: 15,
          color: Colors.grey,
        );
        return FutureBuilder<int>(
          future: selectTotalReadingTimeByBookId(widget.book.id),
          builder: (BuildContext context, AsyncSnapshot<int> snapshot) {
            if (snapshot.hasData) {
              int totalReadingTime = snapshot.data!;
              int hours = totalReadingTime ~/ 3600;
              int minutes = totalReadingTime % 3600 ~/ 60;
              return Padding(
                padding: const EdgeInsets.only(left: 20, right: 20),
                child: Row(
                  children: [
                    highlightDigit(
                      context,
                      L10n.of(context).common_hours(hours),
                      textStyle,
                      digitStyle,
                    ),
                    highlightDigit(
                      context,
                      L10n.of(context).common_minutes(minutes),
                      textStyle,
                      digitStyle,
                    ),
                  ],
                ),
              );
            } else {
              return const Padding(
                padding: EdgeInsets.only(left: 20, right: 20),
                child: CircularProgressIndicator(),
              );
            }
          },
        );
      }

      VerticalDivider verticalDivider = const VerticalDivider(
        color: Colors.black12,
        thickness: 1,
        indent: 15,
        endIndent: 15,
      );

      return SizedBox(
        height: 130,
        width: MediaQuery.of(context).size.width,
        child: Card(
          child: ListView(
            padding: const EdgeInsets.all(10),
            scrollDirection: Axis.horizontal,
            children: [
              Row(
                children: [
                  buildNthBooksItem(),
                  verticalDivider,
                  buildRankItem(),
                  verticalDivider,
                  buildReadingTimeItem(),
                ],
              ),
            ],
          ),
        ),
      );
    }

    Widget buildMoreDetail() {
      Widget buildReadingDetail() {
        return FutureBuilder<List<ReadingTime>>(
          future: selectReadingTimeByBookId(widget.book.id),
          builder: (BuildContext context,
              AsyncSnapshot<List<ReadingTime>> snapshot) {
            if (snapshot.hasData) {
              List<ReadingTime> readingTimes = snapshot.data!;
              return Column(
                children: List.generate(readingTimes.length, (index) {
                  int totalReadingTime = readingTimes[index].readingTime;
                  return Row(
                    children: [
                      Text(
                        readingTimes[index].date!,
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        convertSeconds(totalReadingTime),
                        style: const TextStyle(
                          fontSize: 15,
                        ),
                      ),
                    ],
                  );
                }),
              );
            } else {
              return const CircularProgressIndicator();
            }
          },
        );
      }

      TextStyle textStyle = const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.bold,
      );
      return SingleChildScrollView(
        child: SizedBox(
            // height: 500,
            width: MediaQuery.of(context).size.width,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(15.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '${L10n.of(context).book_detail_import_date}${widget.book.createTime.toString().substring(0, 10)}',
                      style: textStyle,
                    ),
                    Text(
                      '${L10n.of(context).book_detail_last_read_date}${widget.book.updateTime.toString().substring(0, 10)}',
                      style: textStyle,
                    ),
                    const Divider(),
                    SizedBox(
                      // height: 200,
                      child: buildReadingDetail(),
                    ),
                  ],
                ),
              ),
            )),
      );
    }

    return Stack(
      children: [
        Positioned.fill(child: buildBackground()),
        Scaffold(
          backgroundColor: Colors.transparent,
          body: NotificationListener<ScrollNotification>(
            onNotification: (ScrollNotification notification) {
              if (notification is ScrollUpdateNotification) {
                setState(() {
                  _isCollapsed = notification.metrics.pixels > 0;
                });
              }
              return false;
            },
            child: CustomScrollView(
              slivers: [
                SliverAppBar(
                  expandedHeight: 0,
                  pinned: true,
                  stretch: true,
                  backgroundColor: _isCollapsed
                      ? Theme.of(context).colorScheme.surface.withAlpha(80)
                      : Colors.transparent,
                  flexibleSpace: FlexibleSpaceBar(
                    title: AnimatedOpacity(
                      opacity: _isCollapsed ? 1.0 : 0.0,
                      duration: const Duration(milliseconds: 300),
                      child: Text(
                        widget.book.title,
                        style: const TextStyle(fontSize: 16),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    centerTitle: true,
                  ),
                ),
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        if (constraints.maxWidth > 600) {
                          return Row(
                            children: [
                              Expanded(
                                flex: 1,
                                child: Column(
                                  children: [
                                    buildBookBaseDetail(
                                        constraints.maxWidth / 2 - 20),
                                    buildEditButton(),
                                    const SizedBox(height: 5),
                                    buildBookStatistics(),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 20),
                              Expanded(
                                flex: 1,
                                child: Padding(
                                  padding: const EdgeInsets.only(
                                      top: 20, bottom: 20),
                                  child: buildMoreDetail(),
                                ),
                              ),
                            ],
                          );
                        } else {
                          return Column(
                            children: [
                              buildBookBaseDetail(constraints.maxWidth),
                              buildEditButton(),
                              const SizedBox(height: 5),
                              buildBookStatistics(),
                              const SizedBox(height: 15),
                              buildMoreDetail(),
                            ],
                          );
                        }
                      },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
