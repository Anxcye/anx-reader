import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class ReaderNoteMenu extends StatefulWidget {
  const ReaderNoteMenu(
      {super.key, required this.noteId, required this.decoration});

  final int noteId;
  final BoxDecoration decoration;

  @override
  State<ReaderNoteMenu> createState() => ReaderNoteMenuState();
}

class ReaderNoteMenuState extends State<ReaderNoteMenu> {
  BookNote? note;
  bool isLoading = true;
  bool _showNoteDialog = false;
  final textFieldController = TextEditingController();
  bool showSaveButton = false;

  @override
  void initState() {
    super.initState();
    if (mounted) {
      getNoteDetail();
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getNoteDetail() async {
    try {
      note = await selectBookNoteById(widget.noteId);

      if (note != null &&
          note!.readerNote != null &&
          note!.readerNote!.isNotEmpty) {
        textFieldController.text = note!.readerNote!;
        _showNoteDialog = true;
      }
    } finally {
      isLoading = false;
      if (!mounted) return;
      setState(() {});
    }
  }

  void showNoteDialog() {
    setState(() {
      _showNoteDialog = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: AnimatedSize(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeOut,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxHeight: 200),
          child: !_showNoteDialog
              ? null
              : Container(
                  decoration: widget.decoration,
                  padding: const EdgeInsets.all(8),
                  child: SingleChildScrollView(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        TextField(
                          controller: textFieldController,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: L10n.of(context).context_menu_add_note_tips,
                            suffixIcon: !showSaveButton
                                ? null
                                : IconButton(
                                    icon: const Icon(
                                        EvaIcons.checkmark_circle_2_outline),
                                    onPressed: () {
                                      note!.readerNote =
                                          textFieldController.text;
                                      updateBookNoteById(note!);
                                      // remove focus
                                      FocusScope.of(context).unfocus();
                                      setState(() {
                                        showSaveButton = false;
                                      });
                                    },
                                  ),
                          ),
                          maxLines: 5,
                          minLines: 1,
                          onSubmitted: (String value) {
                            note!.readerNote = value;
                            updateBookNoteById(note!);
                          },
                          onChanged: (String value) {
                            setState(() {
                              showSaveButton = true;
                            });
                          },
                        )
                      ],
                    ),
                  ),
                ),
        ),
      ),
    );
  }
}
