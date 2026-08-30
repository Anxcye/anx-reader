import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/book_notes_state.dart';
import 'package:anx_reader/service/notes/export_notes.dart';
import 'package:anx_reader/widgets/bookshelf/book_cover.dart';
import 'package:anx_reader/widgets/book_notes/book_notes_list.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/page/book_detail.dart';
import 'package:anx_reader/widgets/common/container/filled_container.dart';
import 'package:anx_reader/widgets/highlight_digit.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:anx_reader/providers/book_notes.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:iconsx_plus/iconsx_plus.dart';

class BookNotesPage extends ConsumerStatefulWidget {
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
  ConsumerState<BookNotesPage> createState() => _BookNotesPageState();
}

class _BookNotesPageState extends ConsumerState<BookNotesPage> {
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
                  child: BookCover(
                    book: book,
                    height: 180,
                    width: 120,
                    radius: 20,
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
                      child: BookCover(
                        book: book,
                        height: 180,
                        width: 120,
                        radius: 20,
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
    showModalBottomSheet(
      context: context,
      builder: (context) {
        bool mergeChapters = Prefs().notesExportMergeChapters;
        return StatefulBuilder(
          builder: (context, setModalState) {
            return Consumer(
              builder: (context, ref, _) {
                final asyncState = ref.watch(bookNotesControllerProvider(book));
                return asyncState.when(
                  data: (state) {
                    final bool allowMerge =
                        state.exportSortMode.field == NotesSortField.cfi;
                    return Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _exportSortControls(
                            context,
                            ref,
                            state,
                            mergeChapters: mergeChapters,
                            onMergeChanged: (value) {
                              setModalState(() {
                                mergeChapters = value;
                              });
                              Prefs().notesExportMergeChapters = value;
                            },
                          ),
                          const SizedBox(height: 20),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                            children: [
                              _exportButton(
                                context,
                                ref,
                                book,
                                notes,
                                ExportType.copy,
                                mergeChapters: allowMerge && mergeChapters,
                                icon: const Icon(Icons.copy),
                                label: 'Copy',
                              ),
                              _exportButton(
                                context,
                                ref,
                                book,
                                notes,
                                ExportType.md,
                                mergeChapters: allowMerge && mergeChapters,
                                icon: const Icon(IonIcons.logo_markdown),
                                label: 'Markdown',
                              ),
                              _exportButton(
                                context,
                                ref,
                                book,
                                notes,
                                ExportType.txt,
                                mergeChapters: allowMerge && mergeChapters,
                                icon: const Icon(Icons.text_snippet),
                                label: 'Text',
                              ),
                              _exportButton(
                                context,
                                ref,
                                book,
                                notes,
                                ExportType.csv,
                                mergeChapters: false,
                                icon: const Icon(Icons.table_chart),
                                label: 'CSV',
                              ),
                            ],
                          ),
                        ],
                      ),
                    );
                  },
                  loading: () => const SizedBox(
                    height: 120,
                    child: Center(child: CircularProgressIndicator()),
                  ),
                  error: (error, stack) => Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Text('Error: $error'),
                  ),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _exportSortControls(
    BuildContext context,
    WidgetRef ref,
    BookNotesState state, {
    required bool mergeChapters,
    required ValueChanged<bool> onMergeChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          L10n.of(context).notesPageExport,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            _exportSortButton(
              context: context,
              label: L10n.of(context).notesPageSortTime,
              field: NotesSortField.createdTime,
              current: state.exportSortMode,
              onPressed: () {
                if (state.exportSortMode.field == NotesSortField.createdTime) {
                  ref
                      .read(bookNotesControllerProvider(widget.book).notifier)
                      .toggleExportSortDirection();
                } else {
                  ref
                      .read(bookNotesControllerProvider(widget.book).notifier)
                      .setExportSortField(NotesSortField.createdTime);
                }
              },
            ),
            _exportSortButton(
              context: context,
              label: L10n.of(context).notesPageSortChapter,
              field: NotesSortField.cfi,
              current: state.exportSortMode,
              onPressed: () {
                if (state.exportSortMode.field == NotesSortField.cfi) {
                  ref
                      .read(bookNotesControllerProvider(widget.book).notifier)
                      .toggleExportSortDirection();
                } else {
                  ref
                      .read(bookNotesControllerProvider(widget.book).notifier)
                      .setExportSortField(NotesSortField.cfi);
                }
              },
            ),
          ],
        ),
        if (state.exportSortMode.field == NotesSortField.cfi)
          Padding(
            padding: const EdgeInsets.only(top: 12.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        L10n.of(context).notesExportMergeChapters,
                        style: Theme.of(context).textTheme.bodyLarge,
                      ),
                    ),
                    Switch(
                      value: mergeChapters,
                      onChanged: onMergeChanged,
                    ),
                  ],
                ),
                Text(
                  L10n.of(context).notesExportMergeChaptersDescription,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
      ],
    );
  }

  Widget _exportSortButton({
    required BuildContext context,
    required String label,
    required NotesSortField field,
    required NotesSortMode current,
    required VoidCallback onPressed,
  }) {
    final isActive = current.field == field;

    final buttonChild = Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label),
        if (isActive)
          Icon(
            current.direction == SortDirection.asc
                ? EvaIcons.arrow_up
                : EvaIcons.arrow_down,
          ),
      ],
    );

    return Padding(
        padding: const EdgeInsets.only(right: 8.0),
        child: isActive
            ? FilledButton(onPressed: onPressed, child: buttonChild)
            : OutlinedButton(onPressed: onPressed, child: buttonChild));
  }

  Widget _exportButton(
    BuildContext context,
    WidgetRef ref,
    Book book,
    List<BookNote>? notes,
    ExportType type, {
    required bool mergeChapters,
    required Widget icon,
    required String label,
  }) {
    return IconAndText(
      icon: icon,
      text: label,
      onTap: () {
        final controller = ref.read(bookNotesControllerProvider(book).notifier);
        final sorted = controller.notesForExport(
          selectedOnly: false,
          custom: notes,
        );
        Navigator.pop(context);
        exportNotes(
          book,
          sorted,
          type,
          mergeChapterHeadings: mergeChapters,
        );
      },
    );
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
        bottom: false,
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
