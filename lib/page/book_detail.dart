import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/reading_time.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/convert_seconds.dart';
import 'package:anx_reader/utils/get_base_path.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:image_picker/image_picker.dart';

class BookDetail extends StatefulWidget {
  const BookDetail({super.key, required this.book, required this.onRefresh});

  final Book book;
  final Function onRefresh;

  @override
  State<BookDetail> createState() => _BookDetailState();
}

class _BookDetailState extends State<BookDetail> {
  late double rating;
  bool isEditing = false;
  late Image coverImage;

  @override
  void initState() {
    super.initState();
    rating = widget.book.rating;
    coverImage = Image.file(File(widget.book.coverFullPath));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
      ),
        extendBodyBehindAppBar: true,
        body: Stack(children: [
      background(context),
      Padding(
        padding: const EdgeInsets.fromLTRB(20, 80, 20, 20),
        child: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: ListView(
                      padding: const EdgeInsets.all(0),
                      children: [
                        bookBaseDetail(context, widget.book,
                            constraints.maxWidth / 2 - 20),
                        editButton(),
                        const SizedBox(height: 5),
                        bookStatistics(context, widget.book),
                      ],
                    ),
                  ),
                  const SizedBox(width: 20),
                  Expanded(
                    flex: 1,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 20, bottom: 20),
                      child: moreDetail(),
                    ),
                  ),
                ],
              );
            } else {
              return ListView(
                padding: const EdgeInsets.all(0),
                children: [
                  bookBaseDetail(context, widget.book, constraints.maxWidth),
                  editButton(),
                  const SizedBox(height: 5),
                  bookStatistics(context, widget.book),
                  const SizedBox(height: 15),
                  moreDetail(),
                ],
              );
            }
          },
        ),
      ),
    ]));
  }

  ShaderMask background(BuildContext context) {
    return ShaderMask(
      shaderCallback: (rect) {
        return LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Theme.of(context).colorScheme.surface.withOpacity(0.20),
            Colors.transparent,
          ],
        ).createShader(
          Rect.fromLTRB(0, 0, rect.width, rect.height),
        );
      },
      blendMode: BlendMode.dstIn,
      child: Image(
        width: MediaQuery.of(context).size.width,
        height: 600,
        image: coverImage.image,
        fit: BoxFit.cover,
        filterQuality: FilterQuality.high,
        alignment: Alignment.topCenter,
      ),
    );
  }

  Widget bookBaseDetail(BuildContext context, Book book, double width) {
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
                              value: book.readingPercentage,
                              strokeWidth: 6,
                              backgroundColor: Colors.grey[400],
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Theme.of(context).colorScheme.primary),
                            ),
                          ),
                          Positioned.fill(
                            child: Center(
                              child: Text(
                                "${(book.readingPercentage * 100).toStringAsFixed(0)}%",
                                style: const TextStyle(
                                  fontSize: 20,
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

                final ImagePicker picker = ImagePicker();
                final XFile? image =
                    await picker.pickImage(source: ImageSource.gallery);

                if (image != null) {
                  AnxLog.info('BookDetail: Image path: ${image.path}');
                  // Delete the existing cover image file
                  final File oldCoverImageFile =
                      File(widget.book.coverFullPath);
                  if (await oldCoverImageFile.exists()) {
                    await oldCoverImageFile.delete();
                  }

                  String newPath =
                      '${widget.book.coverPath.split('/').sublist(0, widget.book.coverPath.split('/').length - 1).join('/')}/${widget.book.title.length > 20 ? widget.book.title.substring(0, 20) : widget.book.title}-${DateTime.now().millisecond.toString()}.png'
                          .replaceAll(' ', '_');

                  AnxLog.info('BookDetail: New path: $newPath');
                  String newFullPath = getBasePath(newPath);

                  final File newCoverImageFile = File(newFullPath);
                  await newCoverImageFile
                      .writeAsBytes(await image.readAsBytes());
                  widget.book.coverPath = newPath;

                  setState(() {
                    coverImage = Image.file(File(image.path));
                    updateBook(widget.book);
                    widget.onRefresh();
                  });
                }
              },
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  boxShadow: [
                    // Set the shadow
                    BoxShadow(
                      color: Colors.grey.withOpacity(0.5),
                      spreadRadius: 6,
                      blurRadius: 30,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Image(
                    image: coverImage.image,
                    fit: BoxFit.cover,
                    width: 160,
                    height: 230,
                  ),
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
                    initialValue: book.title,
                    enabled: isEditing,
                    style: bookTitleStyle,
                    maxLines: null,
                    minLines: 1,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onChanged: (value) {
                      book.title = value.replaceAll('\n', ' ');
                    },
                  ),
                  const SizedBox(height: 5),
                  TextFormField(
                    initialValue: book.author,
                    enabled: isEditing,
                    style: bookAuthorStyle,
                    maxLines: null,
                    minLines: 1,
                    decoration: const InputDecoration(
                      border: InputBorder.none,
                      isCollapsed: true,
                    ),
                    onChanged: (value) {
                      book.author = value;
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

  Widget editButton() {
    return Row(
      children: [
        const Spacer(),
        isEditing
            ? ElevatedButton(
                child: Row(
                  children: [
                    const Icon(Icons.save),
                    const SizedBox(width: 5),
                    Text(context.bookDetailSave),
                  ],
                ),
                onPressed: () {
                  setState(() {
                    isEditing = false;
                    updateBook(widget.book);
                    widget.onRefresh();
                  });
                },
              )
            : ElevatedButton(
                child: Row(
                  children: [
                    const Icon(Icons.edit),
                    const SizedBox(width: 5),
                    Text(context.bookDetailEdit),
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

  Widget bookStatistics(BuildContext context, Book book) {
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
              nthBooksItem(context),
              verticalDivider,
              rankItem(context),
              verticalDivider,
              readingTimeItem(context),
            ],
          ),
        ],
      )),
    );
  }

  Widget nthBooksItem(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 20, right: 20),
      child: RichText(
        text: TextSpan(
          children: [
            TextSpan(
              text: widget.book.id.toString(),
              style: TextStyle(
                fontSize: 30,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).textTheme.bodyLarge!.color,
              ),
            ),
            TextSpan(
              text: context.bookDetailNthBook,
              style: const TextStyle(
                fontSize: 15,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget rankItem(BuildContext context) {
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

  // Big statistic item. It shows the total reading time of the book.
  Widget readingTimeItem(BuildContext context) {
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
            child: RichText(
              text: TextSpan(
                children: [
                  TextSpan(
                    text: '$hours',
                    style: digitStyle,
                  ),
                  TextSpan(
                    text: ' ${context.commonHours} ',
                    style: textStyle,
                  ),
                  TextSpan(
                    text: '$minutes',
                    style: digitStyle,
                  ),
                  TextSpan(
                    text: ' ${context.commonMinutes}',
                    style: textStyle,
                  ),
                ],
              ),
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

  Widget moreDetail() {
    TextStyle textStyle = const TextStyle(
      fontSize: 15,
      fontWeight: FontWeight.bold,
    );
    return SizedBox(

        // height: 500,
        width: MediaQuery.of(context).size.width,
        child: Card(
          child: Padding(
            padding: const EdgeInsets.all(15.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${context.bookDetailImportDate}${widget.book.createTime.toString().substring(0, 10)}',
                  style: textStyle,
                ),
                const Divider(),
                Text(
                  '${context.bookDetailLastReadDate}${widget.book.updateTime.toString().substring(0, 10)}',
                  style: textStyle,
                ),
                const Divider(),
                SizedBox(
                  height: 200,
                  child: readingDetail(),
                ),
              ],
            ),
          ),
        ));
  }

  Widget readingDetail() {
    return FutureBuilder<List<ReadingTime>>(
      future: selectReadingTimeByBookId(widget.book.id),
      builder:
          (BuildContext context, AsyncSnapshot<List<ReadingTime>> snapshot) {
        if (snapshot.hasData) {
          List<ReadingTime> readingTimes = snapshot.data!;
          return ListView.builder(
            itemCount: readingTimes.length,
            itemBuilder: (BuildContext context, int index) {
              int totalReadingTime = readingTimes[index].readingTime;
              // int hours = totalReadingTime ~/ 3600;
              // int minutes = totalReadingTime % 3600 ~/ 60;
              return Row(
                children: [
                  Text(
                    readingTimes[index].date!,
                    style: const TextStyle(
                      fontSize: 15,
                      // color: Colors.black,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    // '$hours ${context.statisticHours} $minutes ${context.statisticMinutes}',
                    convertSeconds(totalReadingTime),
                    style: const TextStyle(
                      fontSize: 15,
                      // color: Colors.black,
                    ),
                  ),
                ],
              );
            },
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
