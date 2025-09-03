import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/service/notes/export_notes.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/book_notes/book_notes_list.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/widgets/container/filled_container.dart';
import 'package:anx_reader/widgets/highlight_digit.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class BookNotesPage extends StatefulWidget {
  const BookNotesPage({
    super.key,
    required this.book,
    required this.numberOfNotes,
    required this.isMobile,
  });

  final Book book;
  final int numberOfNotes;
  final bool isMobile;

  @override
  State<BookNotesPage> createState() => _BookNotesPageState();
}

class _BookNotesPageState extends State<BookNotesPage> {
  Widget bookInfo(BuildContext context, Book book, int numberOfNotes) {
    TextStyle titleStyle = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      overflow: TextOverflow.ellipsis,
      fontFamily: 'SourceHanSerif',
    );
    return FilledContainer(
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
                    notesStatistic(context, numberOfNotes, book),
                    const SizedBox(
                      height: 25,
                    ),
                    operators(context, book),
                  ],
                ),
              ),
              const SizedBox(width: 30),
              Hero(
                  tag: book.coverFullPath,
                  child: bookCover(
                    context,
                    book,
                    height: 180,
                    width: 120,
                  )),
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
                        notesStatistic(context, numberOfNotes, book),
                        const SizedBox(
                          height: 25,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 30),
                  Hero(
                      tag: book.coverFullPath,
                      child: bookCover(
                        context,
                        book,
                        height: 180,
                        width: 120,
                      )),
                ],
              ),
              operators(context, book),
            ],
          );
        }
      }),
    );
  }

  Future<void> handleExportNotes(BuildContext context, Book book,
      {List<BookNote>? notes}) async {
    notes ??= await selectBookNotesByBookId(book.id);

    showModalBottomSheet(
        context: context,
        builder: (context) {
          return SizedBox(
            height: 100,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                IconAndText(
                    icon: const Icon(Icons.copy),
                    text: 'Copy',
                    onTap: () {
                      Navigator.pop(context);
                      exportNotes(book, notes!, ExportType.copy);
                    }),
                IconAndText(
                    icon: const Icon(IonIcons.logo_markdown),
                    text: 'Markdown',
                    onTap: () {
                      Navigator.pop(context);
                      exportNotes(book, notes!, ExportType.md);
                    }),
                IconAndText(
                    icon: const Icon(Icons.text_snippet),
                    text: 'Text',
                    onTap: () {
                      Navigator.pop(context);
                      exportNotes(book, notes!, ExportType.txt);
                    }),
                IconAndText(
                    icon: const Icon(Icons.table_chart),
                    text: 'CSV',
                    onTap: () {
                      Navigator.pop(context);
                      exportNotes(book, notes!, ExportType.csv);
                    }),
              ],
            ),
          );
        });
  }

  Row operators(BuildContext context, Book book) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      IconAndText(
          icon: const Icon(Icons.details),
          text: L10n.of(context).notesPageDetail,
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => BookDetail(book: book),
              ),
            );
          }),
      IconAndText(
          icon: const Icon(Icons.ios_share),
          text: L10n.of(context).notesPageExport,
          onTap: () {
            handleExportNotes(context, book);
          }),
    ]);
  }

  Widget notesStatistic(BuildContext context, int numberOfNotes, Book book) {
    TextStyle digitStyle = TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      color: Theme.of(context).textTheme.bodyLarge!.color,
    );
    TextStyle textStyle = TextStyle(
        fontSize: 18,
        color: Theme.of(context).textTheme.bodyLarge!.color,
        fontFamily: 'SourceHanSerif');
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        highlightDigit(
          context,
          L10n.of(context).notesNotes(numberOfNotes),
          textStyle,
          digitStyle,
        ),
        Text(
          L10n.of(context).notesReadPercentage(
              '${(book.readingPercentage * 100).toStringAsFixed(2)}%'),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: widget.isMobile
          ? AppBar(
              title: Text(widget.book.title),
            )
          : null,
      extendBodyBehindAppBar: true,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            bookInfo(context, widget.book, widget.numberOfNotes),
            const SizedBox(height: 170),
            BookNotesList(
                book: widget.book,
                reading: false,
                exportNotes: handleExportNotes),
          ],
        ),
      ),
    );
  }
}
