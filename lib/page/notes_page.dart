import 'dart:io';

import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/widgets/tips/notes_tips.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';

import '../dao/book.dart';
import '../dao/reading_time.dart';
import '../models/book.dart';
import 'book_notes_page.dart';

class NotesPage extends StatefulWidget {
  const NotesPage({super.key});

  @override
  State<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends State<NotesPage> {
  Book? _currentBook;
  int _currentNumberOfNotes = 0;

  @override
  void initState() {
    super.initState();
    initialBook();
  }

  void initialBook() async {
    List<Map<String, int>> bookIdAndNotes = await selectAllBookIdAndNotes();

    if (bookIdAndNotes.isNotEmpty) {
      Book book = await selectBookById(bookIdAndNotes[0]['bookId']!);
      setState(() {
        _currentBook = book;
        _currentNumberOfNotes = bookIdAndNotes[0]['numberOfNotes']!;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(context.navBarNotes),
        ),
        body: LayoutBuilder(
          builder: (context, constraints) {
            if (constraints.maxWidth > 600) {
              return Row(
                children: [
                  Expanded(
                    flex: 1,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        notesStatistic(),
                        bookNotesList(false),
                      ],
                    ),
                  ),
                  const VerticalDivider(thickness: 1, width: 1),
                  Expanded(
                    flex: 2,
                    child: detailNotes(),
                  ),
                ],
              );
            } else {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  notesStatistic(),
                  bookNotesList(true),
                ],
              );
            }
          },
        ));
  }

  Widget detailNotes() {
    return _currentBook == null
        ? const Center(child: NotesTips())
        : BookNotesPage(
            book: _currentBook!, numberOfNotes: _currentNumberOfNotes);
  }

  Widget notesStatistic() {
    TextStyle digitStyle = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      // fontFamily: 'SourceHanSerif',
    );
    TextStyle textStyle = const TextStyle(
        fontSize: 18,
        // fontWeight: FontWeight.bold,
        fontFamily: 'SourceHanSerif');
    return FutureBuilder<Map<String, int>>(
        future: selectNumberOfNotesAndBooks(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return Padding(
              padding: const EdgeInsets.all(10.0),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: DefaultTextStyle.of(context).style,
                        children: <TextSpan>[
                          TextSpan(
                            text: '${snapshot.data!['numberOfNotes']}',
                            style: digitStyle,
                          ),
                          TextSpan(
                            text: ' ${context.notesNotesAcross} ',
                            style: textStyle,
                          ),
                        ],
                      ),
                    ),
                    RichText(
                        text: TextSpan(
                            style: DefaultTextStyle.of(context).style,
                            children: [
                          TextSpan(
                            text: '${snapshot.data!['numberOfBooks']}',
                            style: digitStyle,
                          ),
                          TextSpan(
                            text: ' ${context.notesBooks}',
                            style: textStyle,
                          ),
                        ]))
                  ]),
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }

  Widget bookNotesList(bool isMobile) {
    return FutureBuilder<List<Map<String, int>>>(
        future: selectAllBookIdAndNotes(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return snapshot.data!.isEmpty
                ? Expanded(child: const Center(child: NotesTips()))
                : Expanded(
                    child: ListView.builder(
                        itemCount: snapshot.data!.length,
                        itemBuilder: (context, index) {
                          return bookNotes(
                              context,
                              snapshot.data![index]['bookId']!,
                              snapshot.data![index]['numberOfNotes']!,
                              isMobile);
                        }),
                  );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }

  Widget bookNotes(
      BuildContext context, int bookId, int numberOfNotes, bool isMobile) {
    TextStyle numberStyle = const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
    );
    TextStyle numberText = const TextStyle(
      fontSize: 20,
    );
    TextStyle titleStyle = const TextStyle(
      overflow: TextOverflow.ellipsis,
      fontSize: 18,
      fontFamily: 'SourceHanSerif',
      fontWeight: FontWeight.bold,
    );
    TextStyle readingTimeStyle = const TextStyle(
      fontSize: 14,
      color: Colors.grey,
    );
    return FutureBuilder<Book>(
        future: selectBookById(bookId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.done) {
            return GestureDetector(
              onTap: () {
                if (isMobile) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                        builder: (context) => BookNotesPage(
                            book: snapshot.data!,
                            numberOfNotes: numberOfNotes)),
                  );
                } else {
                  setState(() {
                    _currentBook = snapshot.data!;
                    _currentNumberOfNotes = numberOfNotes;
                  });
                }
              },
              child: Card(
                margin: const EdgeInsets.only(top: 8, left: 15, right: 15),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        flex: 3,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            RichText(
                              text: TextSpan(
                                style: DefaultTextStyle.of(context).style,
                                children: [
                                  TextSpan(
                                    text: '$numberOfNotes',
                                    style: numberStyle,
                                  ),
                                  TextSpan(
                                    text: ' ${context.notesNotes}',
                                    style: numberText,
                                  ),
                                ],
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(snapshot.data!.title, style: titleStyle),
                            SizedBox(height: 18),
                            // Reading time
                            FutureBuilder<int>(
                              future: selectTotalReadingTimeByBookId(bookId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  return Text(
                                    '${snapshot.data! ~/ 60} ${context.notesMinutes}',
                                    style: readingTimeStyle,
                                  );
                                } else {
                                  return const CircularProgressIndicator();
                                }
                              },
                            )
                          ],
                        ),
                      ),
                      // Expanded(child: SizedBox()),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: Image.file(
                          File(
                            snapshot.data!.coverPath,
                          ),
                          height: 130,
                          width: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          } else {
            return const CircularProgressIndicator();
          }
        });
  }
}
