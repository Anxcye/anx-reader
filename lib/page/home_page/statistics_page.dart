import 'dart:io';

import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/utils/convert_seconds.dart';
import 'package:anx_reader/widgets/tips/statistic_tips.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../../dao/book.dart';
import '../../dao/reading_time.dart';
import '../../widgets/statistic/chard_card.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
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
                          const ChartCard(),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Expanded(
                      child: ListView(
                        children: const [
                          ThisWeekBooks(),
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
                        ChartCard(),
                        SizedBox(height: 20),
                        ThisWeekBooks(),
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
    return Row(
      children: [
        Expanded(
            child: _buildStatisticCard(
                '{} ${context.statisticBooksRead}', selectTotalNumberOfBook())),
        Expanded(
            child: _buildStatisticCard('{} ${context.statisticDaysOfReading}',
                selectTotalNumberOfDate())),
        Expanded(
            child: _buildStatisticCard(
                '{} ${context.statisticNotes}', selectTotalNumberOfNotes())),
      ],
    );
  }
}

TextStyle totalReadTimeTextStyle() {
  return const TextStyle(
    fontSize: 30,
    fontWeight: FontWeight.bold,
  );
}

TextStyle bigTextStyle() {
  return const TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
  );
}

TextStyle smallTextStyle() {
  return const TextStyle(
    fontSize: 16,
  );
}

Widget _totalReadTime() {
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
            RichText(
              textAlign: TextAlign.start,
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(text: '$H', style: totalReadTimeTextStyle()),
                  TextSpan(
                      text: ' ${context.commonHours} ',
                      style: bigTextStyle()),
                  TextSpan(text: '$M', style: totalReadTimeTextStyle()),
                  TextSpan(
                      text: ' ${context.commonMinutes}',
                      style: bigTextStyle()),
                ],
              ),
            ),
            Text(
              '${Prefs().beginDate.toString().substring(0, 10)} ${context.statisticToPresent}',
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

Widget _buildStatisticCard(String title, Future<int> value) {
  return FutureBuilder<int>(
    future: value,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        var parts = title.split('{}');
        return
            // Card(
            // child:
            Padding(
          padding: const EdgeInsets.all(8.0),
          child: Center(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: <TextSpan>[
                  TextSpan(text: parts[0], style: smallTextStyle()),
                  TextSpan(text: '${snapshot.data}', style: bigTextStyle()),
                  TextSpan(text: parts[1], style: smallTextStyle()),
                ],
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // ),
        );
      } else {
        return const CircularProgressIndicator();
      }
    },
  );
}

class ThisWeekBooks extends StatelessWidget {
  const ThisWeekBooks({super.key});

  final TextStyle titleStyle = const TextStyle(
    fontSize: 30,
    fontFamily: 'SourceHanSerif',
    fontWeight: FontWeight.bold,
    overflow: TextOverflow.ellipsis,
  );

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Map<int, int>>>(
      future: selectThisWeekBooks(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          return Column(

            children: [
              Padding(
                padding: const EdgeInsets.only(left: 10, top: 10, right: 10),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      context.statisticThisWeek,
                      style: titleStyle,
                    ),
                  ],
                ),
              ),
              snapshot.data!.isEmpty
                  ? const Padding(
                      padding: EdgeInsets.only(top: 50),
                      child: StatisticsTips(),
                    )
                  : Column(
                      children: snapshot.data!.map((e) {
                        return BookStatisticItem(
                            bookId: e.keys.first, readingTime: e.values.first);
                      }).toList(),
                    ),
            ],
          );
        } else {
          return const CircularProgressIndicator();
        }
      },
    );
  }
}

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
          return SizedBox(
            height: 150,
            child: Card(
              child: Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.file(
                        File(
                          snapshot.data!.coverFullPath,
                        ),
                        height: 130,
                        width: 90,
                        fit: BoxFit.cover,
                      ),
                    ),
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
                                  child:
                                  Text(snapshot.data!.author,
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
