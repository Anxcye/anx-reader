import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

import '../dao/book_note.dart';
import '../models/book.dart';
import '../models/book_note.dart';

class BookNotesPage extends StatefulWidget {
  const BookNotesPage({
    super.key,
    required this.book,
    required this.numberOfNotes,
  });

  final Book book;
  final int numberOfNotes;

  @override
  State<BookNotesPage> createState() => _BookNotesPageState();
}

class _BookNotesPageState extends State<BookNotesPage> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.book.title),
      ),
      body: ListView(
        children: [
          notesStatistic(context, widget.numberOfNotes),
          bookNotesList(widget.book.id),
        ],
      ),
    );
  }
}

Widget notesStatistic(BuildContext context, int numberOfNotes) {
  TextStyle digitStyle = const TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    // fontFamily: 'SourceHanSerif',
    // color: Colors.black,
  );
  TextStyle textStyle = const TextStyle(
      fontSize: 18,
      // fontWeight: FontWeight.bold,
      // color: Colors.black,
      fontFamily: 'SourceHanSerif');
  return Padding(
    padding: const EdgeInsets.fromLTRB(20, 20, 20, 60),
    child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      RichText(
        text: TextSpan(
          children: <TextSpan>[
            TextSpan(
              text: '$numberOfNotes',
              style: digitStyle,
            ),
            TextSpan(
              text: '  ${context.notesNotes}',
              style: textStyle,
            ),
          ],
        ),
      ),
    ]),
  );
}

Widget bookNotesList(int bookId) {
  return FutureBuilder<List<BookNote>>(
    future: selectBookNotesByBookId(bookId),
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.done) {
        return Column(
          children: snapshot.data!.map((bookNote) {
            return bookNoteItem(context, bookNote);
          }).toList(),
        );
      } else {
        return const CircularProgressIndicator();
      }
    },
  );
}

Widget bookNoteItem(BuildContext context, BookNote bookNote) {
  Color iconColor = Color(int.parse('0x88${bookNote.color}'));
  return Card(
    margin: const EdgeInsets.only(left: 15, right: 15, top: 5, bottom: 5),
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 1,
            child: Padding(
                padding: const EdgeInsets.only(top: 8.0),
                child: bookNote.type == 'highlight'
                    ? Icon(Icons.highlight, color: iconColor)
                    : Icon(Icons.format_underline, color: iconColor)),
          ),
          Expanded(
            flex: 7,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  bookNote.content,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    fontFamily: 'SourceHanSerif',
                  ),
                ),
                Divider(
                  indent: 4,
                  height: 3,
                  color: Colors.grey.shade300,
                ),
                Text(
                  bookNote.chapter,
                  style: const TextStyle(
                    fontSize: 14,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}
