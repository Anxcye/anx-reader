import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:flutter/material.dart';

import '../dao/reading_time.dart';
import '../models/reading_time.dart';

class StatisticPage extends StatefulWidget {
  const StatisticPage({super.key});

  @override
  State<StatisticPage> createState() => _StatisticPageState();
}

class _StatisticPageState extends State<StatisticPage> {
  List<ReadingTime> _readingTimes = [];

  @override
  void initState() {
    super.initState();
    selectAllReadingTime().then((value) {
      setState(() {
        _readingTimes = value;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(context.navBarStatistics),
      ),
      body: ListView.builder(
        itemCount: _readingTimes.length,
        itemBuilder: (context, index) {
          return ListTile(
            title: Text('Book ID: ${_readingTimes[index].bookId}'),
            subtitle: Text('Reading Time: ${_readingTimes[index].readingTime} Read Date: ${_readingTimes[index].date}'),
          );
        },
      ),
    );
  }
}
