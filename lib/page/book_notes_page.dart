import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/service/notes/export_notes.dart';
import 'package:anx_reader/widgets/book_cover.dart';
import 'package:anx_reader/widgets/book_notes/book_notes_list.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/widgets/highlight_digit.dart';
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
    );
    return Card(
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
      ),
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
                operateButton(context, const Icon(Icons.copy), 'Copy', () {
                  Navigator.pop(context);
                  exportNotes(book, notes!, ExportType.copy);
                }),
                operateButton(
                    context,
                    // SvgPicture.asset('assets/icon/Markdown.svg'),
                    const Icon(IonIcons.logo_markdown),
                    'Markdown', () {
                  Navigator.pop(context);
                  exportNotes(book, notes!, ExportType.md);
                }),
                operateButton(context, const Icon(Icons.text_snippet), 'Text',
                    () {
                  Navigator.pop(context);
                  exportNotes(book, notes!, ExportType.txt);
                }),
              ],
            ),
          );
        });
  }

  Row operators(BuildContext context, Book book) {
    return Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      operateButton(context, const Icon(Icons.details),
          L10n.of(context).notes_page_detail, () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BookDetail(book: book, onRefresh: () {}),
          ),
        );
      }),
      // operateButton(context, Icons.search, 'Search', () {}),
      operateButton(context, const Icon(Icons.ios_share),
          L10n.of(context).notes_page_export, () {
        handleExportNotes(context, book);
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
          L10n.of(context).notes_notes(numberOfNotes),
          textStyle,
          digitStyle,
        ),
        Text(
          L10n.of(context).notes_read_percentage(
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
