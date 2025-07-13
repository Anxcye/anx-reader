import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/reading_time.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/book_notes_page.dart';
import 'package:anx_reader/providers/notes_page_current_book.dart';
import 'package:anx_reader/providers/notes_statistics.dart';
import 'package:anx_reader/utils/date/convert_seconds.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/highlight_digit.dart';
import 'package:anx_reader/widgets/tips/notes_tips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class NotesPage extends ConsumerStatefulWidget {
  const NotesPage({super.key, this.controller});

  final ScrollController? controller;

  @override
  ConsumerState<NotesPage> createState() => _NotesPageState();
}

class _NotesPageState extends ConsumerState<NotesPage> {
  late final ScrollController _scrollController =
      widget.controller ?? ScrollController();

  @override
  Widget build(BuildContext context) {
    return Scaffold(body: SafeArea(
      child: LayoutBuilder(
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
                const Expanded(
                  flex: 2,
                  child: NotesDetail(),
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
      ),
    ));
  }

  Widget notesStatistic() {
    final notesStats = ref.watch(notesStatisticsProvider);

    TextStyle digitStyle = const TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
    );
    TextStyle textStyle =
        const TextStyle(fontSize: 18, fontFamily: 'SourceHanSerif');

    return notesStats.when(
      data: (data) {
        return Padding(
          padding: const EdgeInsets.all(10.0),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            highlightDigit(
              context,
              L10n.of(context).notes_notes_across(data['numberOfNotes']!),
              textStyle,
              digitStyle,
            ),
            highlightDigit(
              context,
              L10n.of(context).notes_books(data['numberOfBooks']!),
              textStyle,
              digitStyle,
            ),
          ]),
        );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget bookNotesList(bool isMobile) {
    final bookIdAndNotes = ref.watch(bookIdAndNotesProvider);

    return bookIdAndNotes.when(
      data: (data) {
        return data.isEmpty
            ? const Expanded(child: Center(child: NotesTips()))
            : Expanded(
                child: ListView.builder(
                    controller: _scrollController,
                    itemCount: data.length,
                    itemBuilder: (context, index) {
                      return bookNotes(
                          bookId: data[index]['bookId']!,
                          numberOfNotes: data[index]['numberOfNotes']!,
                          isMobile: isMobile);
                    }),
              );
      },
      loading: () => const CircularProgressIndicator(),
      error: (error, stack) => Text('Error: $error'),
    );
  }

  Widget bookNotes({
    required int bookId,
    required int numberOfNotes,
    required bool isMobile,
  }) {
    TextStyle digitStyle = const TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
    );
    TextStyle textStyle = const TextStyle(
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
                              numberOfNotes: numberOfNotes,
                              isMobile: true,
                            )),
                  );
                } else {
                  ref
                      .read(notesPageCurrentBookProvider.notifier)
                      .setData(snapshot.data!, numberOfNotes);
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
                            highlightDigit(
                              context,
                              L10n.of(context).notes_notes(numberOfNotes),
                              textStyle,
                              digitStyle,
                            ),
                            const SizedBox(height: 8),
                            Text(snapshot.data!.title, style: titleStyle),
                            const SizedBox(height: 18),
                            // Reading time
                            FutureBuilder<int>(
                              future: selectTotalReadingTimeByBookId(bookId),
                              builder: (context, snapshot) {
                                if (snapshot.connectionState ==
                                    ConnectionState.done) {
                                  return Text(
                                    convertSeconds(snapshot.data!),
                                    style: readingTimeStyle,
                                  );
                                } else {
                                  return Text(
                                    convertSeconds(0),
                                    style: readingTimeStyle,
                                  );
                                }
                              },
                            )
                          ],
                        ),
                      ),
                      // Expanded(child: SizedBox()),
                      Hero(
                        tag: isMobile
                            ? snapshot.data!.coverFullPath
                            : '${snapshot.data!.coverFullPath}notMobile',
                        child: bookCover(
                          context,
                          snapshot.data!,
                          height: 130,
                          width: 90,
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

class NotesDetail extends ConsumerWidget {
  const NotesDetail({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ref.watch(notesPageCurrentBookProvider).when(
          data: (current) {
            return BookNotesPage(
                isMobile: false,
                book: current.book,
                numberOfNotes: current.numberOfNotes);
          },
          loading: () => const CircularProgressIndicator(),
          error: (error, stack) => Text('Error: $error'),
        );
  }
}
