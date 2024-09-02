import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/widgets/book_notes/book_notes_list.dart';
import 'package:anx_reader/widgets/reading_page/widget_title.dart';
import 'package:flutter/material.dart';

import 'package:anx_reader/models/book.dart';

class ReadingNotes extends StatelessWidget {
  const ReadingNotes({super.key, required this.book});

  final Book book;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      height: 550,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          widgetTitle(L10n.of(context).navBar_notes, null),
          Expanded(
            child:
                ListView(children: [BookNotesList(book: book, reading: true)]),
          ),
        ],
      ),
    );
  }
}
