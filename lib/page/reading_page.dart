import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:flutter/material.dart';

class ReadingPage extends StatefulWidget {
  final Book book;

  const ReadingPage({super.key, required this.book});

  @override
  State<ReadingPage> createState() => _ReadingPageState();
}

class _ReadingPageState extends State<ReadingPage> {
  late Book _book;

  @override
  void initState() {
    super.initState();
    _book = widget.book;

  }

  @override
  Widget build(BuildContext context){
    return Scaffold(
      appBar: AppBar(
        title: Text(_book.title),
      ),
      body:Text(
        'Reading Page',
        style: TextStyle(fontSize: 20),
    )
    );
  }
}
