import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../dao/reading_time.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.navBarStatistics),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(18.0),
            child: _totalReadTime(),
          ),
          Row(
            children: [
              Expanded(
                  child: _buildStatisticCard(
                      'Read {} Books', selectTotalNumberOfBook())),
              Expanded(
                  child: _buildStatisticCard(
                      'Read {} Days', selectTotalNumberOfDate())),
              Expanded(
                  child: _buildStatisticCard(
                      'Write {} Notes', selectTotalNumberOfNotes())),
            ],
          ),
        ],
      ),
    );
  }
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
        return  RichText(
            textAlign: TextAlign.start,
              text: TextSpan(
            style: DefaultTextStyle.of(context).style,
            children: <TextSpan>[
              TextSpan(text: '$H', style: bigTextStyle()),
              TextSpan(text: 'h', style: smallTextStyle()),
              TextSpan(text: '$M', style: bigTextStyle()),
              TextSpan(text: 'm', style: smallTextStyle()),
            ],
          ),
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
        // return Card(
        //   child:
        return Padding(
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
        return CircularProgressIndicator();
      }
    },
  );
}
