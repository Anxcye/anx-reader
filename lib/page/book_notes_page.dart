import 'dart:io';

import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/service/notes/export_notes.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import '../dao/book_note.dart';
import '../models/book.dart';
import '../models/book_note.dart';
import 'book_detail.dart';

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
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            bookInfo(context, widget.book, widget.numberOfNotes),
            const SizedBox(height: 170),
            bookNotesList(widget.book.id),
          ],
        ),
      ),
    );
  }
}

Widget bookInfo(BuildContext context, Book book, int numberOfNotes) {
  TextStyle titleStyle = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    overflow: TextOverflow.ellipsis,
  );
  return Container(
      child: Card(
    child: Container(
      padding: const EdgeInsets.all(10.0),
      child: LayoutBuilder(builder: (context, constraints) {
        if (constraints.maxWidth > 500) {
          return Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      book.title,
                      style: titleStyle,
                      maxLines: 1,
                    ),
                    notesStatistic(context, numberOfNotes),
                    SizedBox(
                      height: 25,
                    ),
                    opetators(context, book),
                  ],
                ),
              ),
              SizedBox(width: 30),
              bookCover(book),
            ],
          );
        } else {
          return Column(
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          book.title,
                          style: titleStyle,
                          maxLines: 2,
                        ),
                        notesStatistic(context, numberOfNotes),
                        SizedBox(
                          height: 25,
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 30),
                  bookCover(book),
                ],
              ),
              opetators(context, book),
            ],
          );
        }
      }),
    ),
  ));
}

ClipRRect bookCover(Book book) {
  return ClipRRect(
    borderRadius: BorderRadius.circular(8),
    child: Image.file(
      File(
        book.coverPath,
      ),
      height: 180,
      width: 120,
      fit: BoxFit.cover,
    ),
  );
}

Row opetators(BuildContext context, Book book) {
  void handleExportNotes() {
    print("Export notes");
    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                operateButton(context, const Icon(Icons.copy), 'Copy', () {
                  Navigator.pop(context);
                  exportNotes(book.id, ExportType.copy);
                }),
                operateButton(
                    context,
                    SvgPicture.asset('assets/icon/Markdown.svg'),
                    'Markdown', () {
                  Navigator.pop(context);
                  exportNotes(book.id, ExportType.md);
                }),
                operateButton(context, const Icon(Icons.text_snippet), 'Text',
                    () {
                  Navigator.pop(context);
                  exportNotes(book.id, ExportType.txt);
                }),
              ],
            ),
          );
        });
  }

  return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
    // TODO
    operateButton(context, const Icon(Icons.details), 'Detail', () {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BookDetail(book: book, onRefresh: (){}),
        ),
      );
    }),
    // operateButton(context, Icons.search, 'Search', () {}),
    operateButton(context, const Icon(Icons.ios_share), 'Export', () {
      handleExportNotes();
    }),
    // operateButton(context, Icons.ios_share, 'Export', () {}),
  ]);
}

Widget operateButton(
    BuildContext context, Widget icon, String text, Function() onTap) {
  return InkWell(
    onTap: onTap,
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        children: [
          SizedBox(height: 40, width: 40, child: icon),
          Text(text,
              style: TextStyle(
                  color: Theme.of(context).textTheme.bodyLarge!.color)),
        ],
      ),
    ),
  );
}

Widget notesStatistic(BuildContext context, int numberOfNotes) {
  TextStyle digitStyle = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    color: Theme.of(context).textTheme.bodyLarge!.color,
  );
  TextStyle textStyle = TextStyle(
      fontSize: 18,
      color: Theme.of(context).textTheme.bodyLarge!.color,
      fontFamily: 'SourceHanSerif');
  return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    RichText(
      text: TextSpan(
        children: <TextSpan>[
          TextSpan(
            text: '$numberOfNotes',
            style: digitStyle,
          ),
          TextSpan(
            text: ' ${context.notesNotes}',
            style: textStyle,
          ),
        ],
      ),
    ),
  ]);
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
    child: Padding(
      padding: const EdgeInsets.all(8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
              padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
              child: bookNote.type == 'highlight'
                  ? Icon(Icons.highlight, color: iconColor)
                  : Icon(Icons.format_underline, color: iconColor)),
          Expanded(
            // flex: 7,
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
