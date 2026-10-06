import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/widgets/common/axis_flex.dart';
import 'package:flutter/material.dart';
import 'package:iconsx_plus/iconsx_plus.dart';

class ReaderNoteMenu extends StatefulWidget {
  const ReaderNoteMenu({
    super.key,
    this.noteId,
    required this.decoration,
    required this.axis,
    required this.onVisibilityChange,
    required this.onSizeChanged,
    this.onSaved,
  });

  final int? noteId;
  final BoxDecoration decoration;
  final Axis axis;
  final ValueChanged<bool> onVisibilityChange;
  final VoidCallback onSizeChanged;

  /// Close the selection menu after a successful save (desktop parity).
  final VoidCallback? onSaved;

  @override
  State<ReaderNoteMenu> createState() => ReaderNoteMenuState();
}

class ReaderNoteMenuState extends State<ReaderNoteMenu> {
  BookNote? note;
  bool _showNoteDialog = false;
  final textFieldController = TextEditingController();
  final FocusNode _noteFocusNode = FocusNode(debugLabel: 'reader_note');
  bool showSaveButton = false;

  @override
  void initState() {
    super.initState();
    getNoteDetail(widget.noteId);
  }

  @override
  void dispose() {
    textFieldController.dispose();
    _noteFocusNode.dispose();
    super.dispose();
  }

  void _focusNoteField() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      // Hand keyboard to Flutter; CEF otherwise keeps GTK/CEF focus.
      readingPageKey.currentState?.releaseReaderFocusForChrome();
      _noteFocusNode.requestFocus();
    });
  }

  void _notifyVisibility(bool visible) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onVisibilityChange(visible);
      }
    });
  }

  void _notifySizeChange() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        widget.onSizeChanged();
      }
    });
  }

  void _setShowNoteDialog(bool value) {
    if (!mounted) {
      _showNoteDialog = value;
      return;
    }
    if (_showNoteDialog == value) {
      setState(() {});
      _notifySizeChange();
      _notifyVisibility(value);
      if (value) _focusNoteField();
      return;
    }
    setState(() {
      _showNoteDialog = value;
    });
    _notifyVisibility(value);
    _notifySizeChange();
    if (value) _focusNoteField();
  }

  Future<void> getNoteDetail(int? id) async {
    if (id == null) return;
    try {
      final fetchedNote = await bookNoteDao.selectBookNoteById(id);
      note = fetchedNote;

      if (note != null &&
          note!.readerNote != null &&
          note!.readerNote!.isNotEmpty) {
        textFieldController.text = note!.readerNote!;
        _setShowNoteDialog(true);
      }
    } finally {
      if (mounted) {
        setState(() {});
        _notifySizeChange();
      }
    }
  }

  Future<void> showNoteDialog(int noteId) async {
    await getNoteDetail(noteId);
    _setShowNoteDialog(true);
  }

  void saveNote() {
    textFieldController.text = textFieldController.text.trim();
    if (note != null) {
      note!.readerNote = textFieldController.text;
      bookNoteDao.updateBookNoteById(note!);
    }
    _notifySizeChange();
    widget.onSaved?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Expanded(
        child: AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: widget.axis == Axis.vertical ? double.infinity : 200,
          maxWidth: widget.axis == Axis.vertical ? 100 : double.infinity,
        ),
        child: !_showNoteDialog
            ? null
            : Container(
                decoration: widget.decoration,
                padding: const EdgeInsets.all(8),
                child: AxisFlex(
                  reverse: false,
                  axis: widget.axis,
                  children: [
                    Expanded(
                      child: SingleChildScrollView(
                        // scrollDirection: widget.axis,
                        child: TextField(
                          controller: textFieldController,
                          focusNode: _noteFocusNode,
                          autofocus: true,
                          decoration: InputDecoration(
                            border: InputBorder.none,
                            hintText: L10n.of(context).contextMenuAddNoteTips,
                          ),
                          maxLines: widget.axis == Axis.vertical
                              ? double.maxFinite.toInt()
                              : 5,
                          minLines: 1,
                          onSubmitted: (String value) {
                            saveNote();
                          },
                          onChanged: (String value) {
                            setState(() {
                              showSaveButton = true;
                            });
                            _notifySizeChange();
                          },
                        ),
                      ),
                    ),
                    if (showSaveButton)
                      IconButton(
                        icon: const Icon(EvaIcons.checkmark_circle_2_outline),
                        onPressed: saveNote,
                      ),
                  ],
                ),
              ),
      ),
    ));
  }
}
