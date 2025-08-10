import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

class ReaderNoteMenu extends StatefulWidget {
  const ReaderNoteMenu({super.key, this.noteId, required this.decoration});

  final int? noteId;
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
  int? noteId;

  @override
  void initState() {
    super.initState();
    if (mounted) {
      getNoteDetail(widget.noteId);
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> getNoteDetail(int? id) async {
    if (id == null) return;
    try {
      note = await selectBookNoteById(id);

      if (note != null &&
          note!.readerNote != null &&
          note!.readerNote!.isNotEmpty) {
        textFieldController.text = note!.readerNote!;
        setState(() {
          _showNoteDialog = true;
        });
      }
    } finally {
      isLoading = false;
      if (!mounted) return;
      setState(() {});
    }
  }

  Future<void> showNoteDialog(int noteId) async {
    await getNoteDetail(noteId);
    setState(() {
      _showNoteDialog = true;
    });
  }

  void saveNote() {
    textFieldController.text = textFieldController.text.trim();
    note!.readerNote = textFieldController.text;
    updateBookNoteById(note!);
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
                  child: TextField(
                    controller: textFieldController,
                    decoration: InputDecoration(
                      border: InputBorder.none,
                      hintText: L10n.of(context).contextMenuAddNoteTips,
                      suffixIcon: !showSaveButton
                          ? null
                          : IconButton(
                              icon: const Icon(
                                  EvaIcons.checkmark_circle_2_outline),
                              onPressed: () {
                                saveNote();
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
                      saveNote();
                    },
                    onChanged: (String value) {
                      setState(() {
                        showSaveButton = true;
                      });
                    },
                  ),
                ),
              ),
      ),
    ));
  }
}
