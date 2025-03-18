import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';

class MdPage extends StatelessWidget {
  final String title;
  final String content;

  const MdPage({super.key, required this.title, required this.content});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(title)),
      body: Markdown(data: content),
    );
  }
}
