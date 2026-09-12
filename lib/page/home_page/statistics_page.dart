import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/enums/chart_mode.dart';
import 'package:anx_reader/enums/hint_key.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/providers/statistic_data.dart';
import 'package:anx_reader/utils/date/convert_seconds.dart';
import 'package:anx_reader/utils/date/week_of_year.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:anx_reader/widgets/common/container/outlined_container.dart';
import 'package:anx_reader/widgets/hint/hint_banner.dart';
import 'package:anx_reader/widgets/statistic/statistic_card.dart';
import 'package:anx_reader/widgets/statistic/statistics_dashboard_title.dart';
import 'package:anx_reader/widgets/statistic/statistics_dashboard.dart';
import 'package:anx_reader/widgets/tips/statistic_tips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key, this.controller});

  final ScrollController? controller;

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int totalNumberOfBook = 0;
  int totalNumberOfDate = 0;
  int totalNumberOfNotes = 0;
  late final ScrollController _scrollController =
      widget.controller ?? ScrollController();

  void setNumbers() async {
    final numberOfBook = await readingTimeDao.selectTotalNumberOfBook();
    final numberOfDate = await readingTimeDao.selectTotalNumberOfDate();
    final numberOfNotes = await readingTimeDao.selectTotalNumberOfNotes();
    setState(() {
      totalNumberOfBook = numberOfBook;
      totalNumberOfDate = numberOfDate;
      totalNumberOfNotes = numberOfNotes;
    });
  }

  @override
  void initState() {
    setNumbers();
    super.initState();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title: Text(context.navBarStatistics),
      // ),
      body: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          child: Column(
            children: [
              StatisticsDashboardTitle(),
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 600) {
                      return Row(
                        children: [
                          Expanded(
                            child: SingleChildScrollView(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  StatisticsDashboard(),
                                  const StatisticCard(),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 20),
                          Expanded(
                            child: ListView(
                              controller: _scrollController,
                              children: const [
                                DateBooks(),
                              ],
                            ),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: ListView(
                                padding: const EdgeInsets.only(bottom: 80),
                                controller: _scrollController,
                                children: const [
                                  StatisticsDashboard(),
                                  StatisticCard(),
                                  SizedBox(height: 20),
                                  DateBooks(),
                                ]),
                          ),
                        ],
                      );
                    }
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class DateBooks extends ConsumerStatefulWidget {
  const DateBooks({super.key});

  @override
  ConsumerState<DateBooks> createState() => _DateBooksState();
}

class _DateBooksState extends ConsumerState<DateBooks> {
  final TextStyle titleStyle = const TextStyle(
    fontSize: 30,
    fontFamily: 'SourceHanSerif',
    fontWeight: FontWeight.bold,
    overflow: TextOverflow.ellipsis,
  );

  List<int> deleteBookIds = [];

  @override
  void dispose() {
    super.dispose();
    if (deleteBookIds.isNotEmpty) {
      readingTimeDao.deleteReadingTimeByBookId(deleteBookIds);
    }
  }

  @override
  Widget build(BuildContext context) {
    final statisticData = ref.watch(statisticDataProvider);

    Widget dragToDelete(Widget child, int bookId) {
      return StatefulBuilder(builder: (context, localSetState) {
        if (deleteBookIds.contains(bookId)) {
          return OutlinedContainer(
            margin: const EdgeInsets.only(bottom: 10),
            height: 146,
            padding: const EdgeInsets.all(8.0),
            child: Column(
              children: [
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete,
                          size: 30,
                        ),
                        Text(
                          L10n.of(context).statisticDeletedRecords,
                          style: TextStyle(
                              fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    FilledButton(
                        onPressed: () {
                          localSetState(() {
                            deleteBookIds.remove(bookId);
                          });
                        },
                        child: Text(L10n.of(context).commonUndo)),
                  ],
                ),
                const Spacer(),
                const Divider(),
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18),
                    Text(L10n.of(context).statisticDeletedRecordsTips),
                  ],
                ),
              ],
            ),
          );
        }
        ActionPane actionPane = ActionPane(
          motion: const StretchMotion(),
          children: [
            SlidableAction(
              onPressed: (context) {
                localSetState(() {
                  deleteBookIds.add(bookId);
                });
              },
              icon: Icons.delete,
              label: L10n.of(context).commonDelete,
              backgroundColor: Theme.of(context).scaffoldBackgroundColor,
            ),
          ],
        );
        return Slidable(
          key: ValueKey(bookId),
          startActionPane: actionPane,
          endActionPane: actionPane,
          child: child,
        );
      });
    }

    return statisticData.when(
      data: (data) {
        final title = data.isSelectingDay
            ? data.date.toString().substring(0, 10)
            : data.mode == ChartMode.week
                ? weekOfYear(data.date)
                : data.mode == ChartMode.month
                    ? '${data.date.year}.${data.date.month}'
                    : data.mode == ChartMode.year
                        ? data.date.year.toString()
                        : L10n.of(context).statisticAllTime;

        final books = data.bookReadingTime;
        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: titleStyle),
                ],
              ),
            ),
            if (books.isEmpty)
              const Padding(
                padding: EdgeInsets.only(top: 50),
                child: StatisticsTips(),
              )
            else
              Column(
                children: [
                  HintBanner(
                    icon: const Icon(Icons.swipe_left),
                    hintKey: HintKey.statisticsSwipeToDelete,
                    margin: const EdgeInsets.only(bottom: 10),
                    child: Text(L10n.of(context).statisticsSwipeToDeleteHint),
                  ),
                  ...books.map((bookMap) {
                    final book = bookMap.keys.first;
                    final readingTime = bookMap.values.first;
                    return dragToDelete(
                      BookStatisticItem(
                        bookId: book.id,
                        readingTime: readingTime,
                      ),
                      book.id,
                    );
                  })
                ],
              ),
          ],
        );
      },
      loading: () => const Center(
        child: CircularProgressIndicator(),
      ),
      error: (error, stack) => Center(
        child: Text('Error: $error'),
      ),
    );
  }
}

class BookStatisticItem extends StatelessWidget {
  const BookStatisticItem(
      {super.key, required this.bookId, required this.readingTime});

  final int bookId;
  final int readingTime;
  final TextStyle bookTitleStyle = const TextStyle(
    fontSize: 20,
    fontFamily: 'SourceHanSerif',
    fontWeight: FontWeight.bold,
    overflow: TextOverflow.ellipsis,
  );
  final TextStyle bookAuthorStyle = const TextStyle(
    fontSize: 12,
    color: Colors.grey,
    overflow: TextOverflow.ellipsis,
  );
  final TextStyle bookReadingTimeStyle = const TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book>(
      future: bookDao.selectBookById(bookId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BookDetail(book: snapshot.data!)));
            },
            child: FilledContainer(
              margin: const EdgeInsets.only(bottom: 10),
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Hero(
                      tag: snapshot.data!.coverFullPath,
                      child: BookCover(
                        book: snapshot.data!,
                        height: 130,
                        width: 90,
                        radius: 20,
                      )),
                  const SizedBox(width: 15),
                  Flexible(
                    child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(snapshot.data!.title, style: bookTitleStyle),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(snapshot.data!.author,
                                    style: bookAuthorStyle),
                              ),
                              Text(
                                  // getReadingTime(context),
                                  convertSeconds(readingTime),
                                  textAlign: TextAlign.end,
                                  style: bookReadingTimeStyle),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Row(
                            children: [
                              Expanded(
                                child: LinearProgressIndicator(
                                  value: snapshot.data!.readingPercentage,
                                  backgroundColor: Colors.grey[300],
                                  valueColor: AlwaysStoppedAnimation<Color>(
                                      Theme.of(context).colorScheme.primary),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Text(
                                  '${(snapshot.data!.readingPercentage * 100).toInt()} %'),
                            ],
                          ),
                        ]),
                  ),
                ],
              ),
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
