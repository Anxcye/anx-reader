import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/enums/chart_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/providers/statistic_data.dart';
import 'package:anx_reader/utils/date/convert_seconds.dart';
import 'package:anx_reader/utils/date/week_of_year.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/highlight_digit.dart';
import 'package:anx_reader/widgets/statistic/statistic_card.dart';
import 'package:anx_reader/widgets/statistic/statistic_card.dart';
import 'package:anx_reader/widgets/tips/statistic_tips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  int totalNumberOfBook = 0;
  int totalNumberOfDate = 0;
  int totalNumberOfNotes = 0;

  void setNumbers() async {
    final numberOfBook = await selectTotalNumberOfBook();
    final numberOfDate = await selectTotalNumberOfDate();
    final numberOfNotes = await selectTotalNumberOfNotes();
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
        child: Padding(
          padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
          child: LayoutBuilder(
            builder: (context, constraints) {
              if (constraints.maxWidth > 600) {
                return Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _totalReadTime(),
                          const SizedBox(height: 20),
                          baseStatistic(context),
                          const StatisticCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ListView(
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
                    _totalReadTime(),
                    const SizedBox(height: 20),
                    baseStatistic(context),
                    const SizedBox(height: 30),
                    Expanded(
                      child: ListView(children: const [
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
      ),
    );
  }

  Row baseStatistic(BuildContext context) {
    TextStyle digitStyle = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );

    TextStyle textStyle = const TextStyle(
      fontSize: 16,
    );
    return Row(
      children: [
        Expanded(
            child: highlightDigit(
                context,
                L10n.of(context).statistic_books_read(totalNumberOfBook),
                textStyle,
                digitStyle)),
        Expanded(
            child: highlightDigit(
                context,
                L10n.of(context).statistic_days_of_reading(totalNumberOfDate),
                textStyle,
                digitStyle)),
        Expanded(
            child: highlightDigit(
                context,
                L10n.of(context).statistic_notes(totalNumberOfNotes),
                textStyle,
                digitStyle)),
      ],
    );
  }
}

Widget _totalReadTime() {
  TextStyle textStyle = const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );

  TextStyle digitStyle = const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );

  return FutureBuilder<int>(
    future: selectTotalReadingTime(),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        // 12 h 34 m
        int H = snapshot.data! ~/ 3600;
        int M = (snapshot.data! % 3600) ~/ 60;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                highlightDigit(
                  context,
                  L10n.of(context).common_hours(H),
                  digitStyle,
                  textStyle,
                ),
                highlightDigit(
                  context,
                  L10n.of(context).common_minutes(M),
                  digitStyle,
                  textStyle,
                ),
              ],
            ),
            Text(
              '${Prefs().beginDate.toString().substring(0, 10)} ${L10n.of(context).statistic_to_present}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.grey[600],
              ),
            )
          ],
        );
      } else {
        return const CircularProgressIndicator();
      }
    },
  );
}

class DateBooks extends ConsumerWidget {
  const DateBooks({super.key});

  final TextStyle titleStyle = const TextStyle(
    fontSize: 30,
    fontFamily: 'SourceHanSerif',
    fontWeight: FontWeight.bold,
    overflow: TextOverflow.ellipsis,
  );

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statisticData = ref.watch(statisticDataProvider);

    return statisticData.when(
      data: (data) {
        final books = data.bookReadingTime;

        return Column(
          children: [
            Padding(
              padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    data.mode == ChartMode.week
                        ? weekOfYear(data.date)
                        : data.mode == ChartMode.month
                            ? '${data.date.year}.${data.date.month}'
                            : data.date.year.toString(),
                    style: titleStyle,
                  ),
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
                children: books.map((bookMap) {
                  final book = bookMap.keys.first;
                  final readingTime = bookMap.values.first;
                  return BookStatisticItem(
                    bookId: book.id,
                    readingTime: readingTime,
                  );
                }).toList(),
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
// class DateBooks extends StatelessWidget {
//   const DateBooks({super.key});
//
//   final TextStyle titleStyle = const TextStyle(
//     fontSize: 30,
//     fontFamily: 'SourceHanSerif',
//     fontWeight: FontWeight.bold,
//     overflow: TextOverflow.ellipsis,
//   );
//
//   @override
//   Widget build(BuildContext context) {
//     return FutureBuilder<List<Map<int, int>>>(
//       future: selectThisWeekBooks(),
//       builder: (context, snapshot) {
//         if (snapshot.connectionState == ConnectionState.done) {
//           return Column(
//             children: [
//               Padding(
//                 padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
//                 child: Row(
//                   crossAxisAlignment: CrossAxisAlignment.start,
//                   children: [
//                     Text(
//                       L10n.of(context).statistic_this_week,
//                       style: titleStyle,
//                     ),
//                   ],
//                 ),
//               ),
//               snapshot.data!.isEmpty
//                   ? const Padding(
//                       padding: EdgeInsets.only(top: 50),
//                       child: StatisticsTips(),
//                     )
//                   : Column(
//                       children: snapshot.data!.map((e) {
//                         return BookStatisticItem(
//                             bookId: e.keys.first, readingTime: e.values.first);
//                       }).toList(),
//                     ),
//             ],
//           );
//         } else {
//           return const CircularProgressIndicator();
//         }
//       },
//     );
//   }
// }

class BookStatisticItem extends StatelessWidget {
  const BookStatisticItem(
      {super.key, required this.bookId, required this.readingTime});

  final int bookId;
  final int readingTime;
  final TextStyle bookTitleStyle = const TextStyle(
    fontSize: 24,
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
    fontSize: 20,
    fontWeight: FontWeight.bold,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Book>(
      future: selectBookById(bookId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => BookDetail(book: snapshot.data!)));
            },
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Hero(
                        tag: snapshot.data!.coverFullPath,
                        child: bookCover(
                          context,
                          snapshot.data!,
                          height: 130,
                          width: 90,
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
            ),
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}
