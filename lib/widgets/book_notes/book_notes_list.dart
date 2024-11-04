import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/service/book.dart';
import 'package:anx_reader/utils/time_to_human.dart';
import 'package:anx_reader/widgets/delete_confirm.dart';
import 'package:anx_reader/widgets/context_menu/excerpt_menu.dart';
import 'package:anx_reader/widgets/tips/notes_tips.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:sticky_headers/sticky_headers.dart';

class BookNotesList extends StatefulWidget {
  const BookNotesList({
    super.key,
    required this.book,
    required this.reading,
    this.exportNotes,
  });

  final Book book;
  final bool reading;
  final Function(BuildContext context, Book book, {List<BookNote>? notes})?
      exportNotes;

  @override
  State<BookNotesList> createState() => _BookNotesListState();
}

class _BookNotesListState extends State<BookNotesList> {
  List<BookNote> bookNotes = [];
  List<BookNote> showNotes = [];
  List<BookNote> selectedNotes = [];
  String sortType = 'cfi';
  bool asc = true;
  List<bool> typeColorSelected =
      List.filled(notesType.length * notesColors.length, true);

  @override
  void initState() {
    super.initState();
    _loadBookNotes();
  }

  @override
  void didUpdateWidget(covariant BookNotesList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.book.id != widget.book.id) {
      _loadBookNotes();
    }
  }

  Future<void> _loadBookNotes() async {
    List<BookNote> notes = await selectBookNotesByBookId(widget.book.id);
    setState(() {
      bookNotes = notes;
      showNotes = bookNotes;
    });
  }

  Widget bookNoteItem(BuildContext context, BookNote bookNote, bool selected) {
    Color iconColor = Color(int.parse('0xaa${bookNote.color}'));
    TextStyle infoStyle = const TextStyle(
      fontSize: 14,
      color: Colors.grey,
    );
    return GestureDetector(
      onTap: () {
        if (selectedNotes.isNotEmpty) {
          setState(() {
            if (selectedNotes.contains(bookNote)) {
              selectedNotes.remove(bookNote);
            } else {
              selectedNotes.add(bookNote);
            }
          });
        } else {
          if (widget.reading) {
            epubPlayerKey.currentState!.goToCfi(bookNote.cfi);
          } else {
            pushToReadingPage(context, widget.book, cfi: bookNote.cfi);
          }
        }
      },
      onLongPress: () {
        setState(() {
          if (selectedNotes.contains(bookNote)) {
            selectedNotes.remove(bookNote);
          } else {
            selectedNotes.add(bookNote);
          }
        });
      },
      child: Card(
        shadowColor: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                  padding: const EdgeInsets.only(left: 10, right: 10, top: 10),
                  child: Icon(
                    notesType.firstWhere(
                        (element) => element['type'] == bookNote.type)['icon'],
                    color: iconColor,
                  )),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      bookNote.content,
                      style: const TextStyle(
                        fontSize: 16,
                      ),
                    ),
                    Divider(
                      indent: 4,
                      height: 3,
                      color: Colors.grey.shade300,
                    ),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            bookNote.chapter,
                            style: infoStyle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          timeToHuman(bookNote.createTime, context),
                          style:infoStyle,
                        )
                      ],
                    ),
                  ],
                ),
              ),
              if (selectedNotes.isNotEmpty)
                IconButton(
                  onPressed: () {
                    setState(() {
                      if (selectedNotes.contains(bookNote)) {
                        selectedNotes.remove(bookNote);
                      } else {
                        selectedNotes.add(bookNote);
                      }
                    });
                  },
                  icon: Icon(
                    selectedNotes.contains(bookNote)
                        ? EvaIcons.checkmark_circle
                        : Icons.circle_outlined,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget filterButton(BuildContext context) {
    int epubCfiCompare(String a, String b) {
      List<String> replace(String str) {
        return str
            .replaceAll('epubcfi(/', '')
            .replaceAll(')', '')
            .replaceAll(',', '')
            .split('/');
      }

      List<String> componentsA = replace(a);
      List<String> componentsB = replace(b);

      for (int i = 0; i < componentsA.length && i < componentsB.length; i++) {
        String compA = componentsA[i];
        String compB = componentsB[i];

        if (compA.isEmpty || compB.isEmpty) {
          continue;
        }
        if (compA != compB) {
          if (compA.contains(':') && compB.contains(':')) {
            int locA = int.tryParse(compA.split(':')[1]) ?? 0;
            int locB = int.tryParse(compB.split(':')[1]) ?? 0;
            return locA.compareTo(locB);
          } else {
            int numA = int.tryParse(compA.replaceAll('!', '')) ?? 0;
            int numB = int.tryParse(compB.replaceAll('!', '')) ?? 0;
            return numA.compareTo(numB);
          }
        }
      }

      return componentsA.length.compareTo(componentsB.length);
      // return 0;
    }

    void sortAndFilter() {
      List<BookNote> filterNotes = [];

      for (int i = 0; i < bookNotes.length; i++) {
        Map<String, dynamic> typeMap = notesType
            .firstWhere((element) => element['type'] == bookNotes[i].type);
        String color = bookNotes[i].color.toUpperCase();
        int index = notesType.indexOf(typeMap) * notesColors.length +
            notesColors.indexOf(color);

        if (typeColorSelected[index]) {
          filterNotes.add(bookNotes[i]);
        }
      }

      if (sortType == 'time') {
        filterNotes.sort((a, b) {
          if (asc) {
            return a.createTime!.compareTo(b.createTime!);
          } else {
            return b.createTime!.compareTo(a.createTime!);
          }
        });
      } else {
        filterNotes.sort((a, b) {
          if (asc) {
            return epubCfiCompare(a.cfi, b.cfi);
          } else {
            return epubCfiCompare(b.cfi, a.cfi);
          }
        });
      }
      showNotes = filterNotes;
    }

    Widget sortButton(
      BuildContext context,
      StateSetter sheetState,
      String text,
      String type,
    ) {
      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: ElevatedButton(
          style: ElevatedButton.styleFrom(
              backgroundColor: sortType == type
                  ? Theme.of(context).colorScheme.primary
                  : Theme.of(context).colorScheme.surface,
              foregroundColor: sortType == type
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurface),
          onPressed: () {
            setState(() {
              sheetState(() {
                sortType = type;
                asc = !asc;
                sortAndFilter();
              });
            });
          },
          child: Row(
            children: [
              Text(text),
              if (sortType == type)
                Icon(
                  asc ? EvaIcons.arrow_up : EvaIcons.arrow_down,
                )
            ],
          ),
        ),
      );
    }

    Widget filterButton(
      BuildContext context,
      StateSetter sheetState,
      IconData icon,
      int typeIndex,
    ) {
      Widget colorButton(Color color, int index) => IconButton(
          onPressed: () {
            setState(() {
              sheetState(() {
                typeColorSelected[index] = !typeColorSelected[index];
                sortAndFilter();
              });
            });
          },
          icon: Icon(
              typeColorSelected[index]
                  ? EvaIcons.checkmark_circle_2
                  : Icons.circle,
              color: color),
          iconSize: 35);

      return Padding(
        padding: const EdgeInsets.all(8.0),
        child: Row(
          children: [
            IconButton(
              onPressed: () {
                setState(() {
                  sheetState(() {
                    for (int i = typeIndex * notesColors.length;
                        i < (typeIndex + 1) * notesColors.length;
                        i++) {
                      typeColorSelected[i] = !typeColorSelected[i];
                    }

                    sortAndFilter();
                  });
                });
              },
              icon: Icon(icon),
            ),
            const Spacer(),
            ...notesColors.map((color) {
              return colorButton(
                Color(int.parse('0x99$color')),
                typeIndex * notesColors.length + notesColors.indexOf(color),
              );
            }),
          ],
        ),
      );
    }

    void showFilterBottomSheet() {
      showModalBottomSheet(
        context: context,
        builder: (BuildContext context) {
          return Padding(
            padding: const EdgeInsets.fromLTRB(20, 0, 20, 10),
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter sheetState) => Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      sortButton(
                        context,
                        sheetState,
                        L10n.of(context).notes_page_sort_time,
                        'time',
                      ),
                      sortButton(
                        context,
                        sheetState,
                        L10n.of(context).notes_page_sort_chapter,
                        'cfi',
                      ),
                      const Spacer(),
                    ],
                  ),
                  for (int i = 0; i < notesType.length; i++)
                    filterButton(context, sheetState, notesType[i]['icon'], i),
                  Row(
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            setState(() {
                              sheetState(() {
                                typeColorSelected =
                                    List.filled(typeColorSelected.length, true);
                                sortAndFilter();
                              });
                            });
                          },
                          child:
                              Text(L10n.of(context).notes_page_filter_reset)),
                      const SizedBox(width: 10),
                      Expanded(
                        child: ElevatedButton(
                            style: ElevatedButton.styleFrom(
                                backgroundColor:
                                    Theme.of(context).colorScheme.primary,
                                foregroundColor:
                                    Theme.of(context).colorScheme.onPrimary),
                            onPressed: Navigator.of(context).pop,
                            child: Text(L10n.of(context)
                                .notes_page_view_all_n_notes(
                                    showNotes.length))),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      );
    }

    return IconButton(
        onPressed: showFilterBottomSheet,
        icon: showNotes.length == bookNotes.length
            ? const Icon(EvaIcons.funnel_outline)
            : const Icon(EvaIcons.funnel));
  }

  Widget header(BuildContext context) {
    Color buttonColor = Theme.of(context).colorScheme.primary;
    List<Widget> filter = [
      const Spacer(),
      filterButton(context),
    ];
    List<Widget> selected = [
      IconButton(
        onPressed: () {
          setState(() {
            if (selectedNotes.length == showNotes.length) {
              selectedNotes.clear();
            } else {
              selectedNotes = List.from(showNotes);
            }
          });
        },
        icon: Icon(
          selectedNotes.length == showNotes.length
              ? EvaIcons.checkmark_circle
              : Icons.circle_outlined,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
      const Spacer(),
      DeleteConfirm(
        delete: () {
          for (int i = 0; i < selectedNotes.length; i++) {
            deleteBookNoteById(selectedNotes[i].id!);
          }
          setState(() {
            selectedNotes.clear();
            _loadBookNotes();
          });
        },
        deleteIcon: Icon(
          EvaIcons.trash_2,
          color: buttonColor,
        ),
        confirmIcon: const Icon(
          EvaIcons.close_circle,
          color: Colors.red,
        ),
      ),
      if (!widget.reading)
        IconButton(
            onPressed: () {
              widget.exportNotes!(context, widget.book, notes: selectedNotes);
            },
            icon: Icon(
              Icons.ios_share,
              color: buttonColor,
            )),
    ];

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: selectedNotes.isNotEmpty ? selected : filter,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        StickyHeader(
          header: header(context),
          content: showNotes.isEmpty
              ? const Column(
                  children: [
                    Divider(),
                    NotesTips(),
                  ],
                )
              : Column(
                  children: showNotes.map((bookNote) {
                    return bookNoteItem(context, bookNote, false);
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
