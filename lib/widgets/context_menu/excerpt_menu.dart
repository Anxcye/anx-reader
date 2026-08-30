import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/constants/note_annotations.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/enums/search_display_mode.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/service/search/search_engine.dart';
import 'package:anx_reader/service/tts/tts_handler.dart';
import 'package:anx_reader/utils/env_var.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/book_share/excerpt_share_service.dart';
import 'package:anx_reader/widgets/common/axis_flex.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class ExcerptMenu extends StatefulWidget {
  final String annoCfi;
  final String annoContent;
  final int? id;
  final Function() onClose;
  final bool footnote;
  final BoxDecoration decoration;
  final Function() toggleTranslationMenu;
  final void Function({bool? show}) toggleReaderNoteMenu;
  final void Function({bool? show, String? query}) toggleSearchMenu;
  final Future<void> Function(int noteId) openReaderNoteMenu;
  final void Function(int noteId) onNoteCreated;
  final Axis axis;
  final bool reverse;

  const ExcerptMenu({
    super.key,
    required this.annoCfi,
    required this.annoContent,
    this.id,
    required this.onClose,
    required this.footnote,
    required this.decoration,
    required this.toggleTranslationMenu,
    required this.toggleReaderNoteMenu,
    required this.toggleSearchMenu,
    required this.openReaderNoteMenu,
    required this.onNoteCreated,
    required this.axis,
    required this.reverse,
  });

  @override
  ExcerptMenuState createState() => ExcerptMenuState();
}

class ExcerptMenuState extends State<ExcerptMenu> {
  bool deleteConfirm = false;
  int? noteId;
  BookNote? _currentNote;
  late String annoType;
  late String annoColor;

  @override
  initState() {
    super.initState();
    annoType = Prefs().annotationType;
    annoColor = Prefs().annotationColor;
    _initializeExistingNote();
  }

  Future<void> _initializeExistingNote() async {
    final existingId = widget.id;
    if (existingId == null) {
      return;
    }

    try {
      final note = await bookNoteDao.selectBookNoteById(existingId);
      if (!mounted) {
        return;
      }
      setState(() {
        _currentNote = note;
        noteId = note.id;
        annoType = note.type;
        annoColor = note.color;
      });
      if (!widget.footnote &&
          note.readerNote != null &&
          note.readerNote!.isNotEmpty) {
        await widget.openReaderNoteMenu(note.id!);
      }
    } catch (_) {
      // When the note cannot be loaded we keep the defaults from Prefs.
    }
  }

  Future<BookNote?> _fetchLatestNote() async {
    final existingId = noteId ?? widget.id;
    if (existingId == null) {
      return null;
    }

    try {
      return await bookNoteDao.selectBookNoteById(existingId);
    } catch (_) {
      return null;
    }
  }

  Future<BookNote> _persistNote(
      {String? color, String? type, String? content}) async {
    final existingNote = await _fetchLatestNote() ?? _currentNote;
    final now = DateTime.now();

    final resolvedContent = (content ?? widget.annoContent).trim().isNotEmpty
        ? (content ?? widget.annoContent)
        : (existingNote?.content ?? widget.annoContent);
    final resolvedType = type ?? existingNote?.type ?? annoType;
    final resolvedColor = color ?? existingNote?.color ?? annoColor;

    final BookNote bookNote = BookNote(
      id: existingNote?.id ?? widget.id,
      bookId:
          existingNote?.bookId ?? epubPlayerKey.currentState!.widget.book.id,
      content: resolvedContent,
      cfi: existingNote?.cfi ?? widget.annoCfi,
      chapter:
          existingNote?.chapter ?? epubPlayerKey.currentState!.chapterTitle,
      type: resolvedType,
      color: resolvedColor,
      readerNote: existingNote?.readerNote,
      createTime: existingNote?.createTime ?? now,
      updateTime: now,
    );

    final id = await bookNoteDao.save(bookNote);
    bookNote.setId(id);
    widget.onNoteCreated(id);

    if (mounted) {
      setState(() {
        _currentNote = bookNote;
        noteId = id;
        annoType = resolvedType;
        annoColor = resolvedColor;
      });
    } else {
      _currentNote = bookNote;
      noteId = id;
      annoType = resolvedType;
      annoColor = resolvedColor;
    }

    return bookNote;
  }

  Icon deleteIcon() {
    return deleteConfirm
        ? const Icon(
            EvaIcons.close_circle,
            color: Colors.red,
          )
        : const Icon(Icons.delete);
  }

  void deleteHandler() {
    if (deleteConfirm) {
      if (widget.id != null) {
        bookNoteDao.deleteBookNoteById(widget.id!);
        epubPlayerKey.currentState!.removeAnnotation(widget.annoCfi);
      }
      widget.onClose();
    } else {
      setState(() {
        deleteConfirm = true;
      });
    }
  }

  Future<void> onColorSelected(String color, {bool close = true}) async {
    Prefs().annotationColor = color;
    if (mounted) {
      setState(() {
        annoColor = color;
      });
    } else {
      annoColor = color;
    }
    final bookNote = await _persistNote(color: color);
    epubPlayerKey.currentState!.addAnnotation(bookNote);
    if (close) {
      widget.onClose();
    }
  }

  Future<void> onTypeSelected(String type) async {
    Prefs().annotationType = type;
    if (mounted) {
      setState(() {
        annoType = type;
      });
    } else {
      annoType = type;
    }
    final bookNote = await _persistNote(type: type);
    epubPlayerKey.currentState!.addAnnotation(bookNote);
  }

  Widget iconButton({required Icon icon, required Function() onPressed}) {
    return IconButton(
      padding: const EdgeInsets.all(2),
      constraints: const BoxConstraints(),
      style: const ButtonStyle(
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
      ),
      icon: icon,
      onPressed: onPressed,
    );
  }

  Widget colorButton(String color) {
    return iconButton(
      icon: Icon(
        Icons.circle,
        color: Color(int.parse('0x88$color')),
      ),
      onPressed: () {
        onColorSelected(color);
      },
    );
  }

  Widget typeButton(String type, IconData icon) {
    return iconButton(
      icon: Icon(icon,
          color: annoType == type ? Color(int.parse('0xff$annoColor')) : null),
      onPressed: () {
        onTypeSelected(type);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget annotationMenu = Container(
      padding: const EdgeInsets.all(6),
      decoration: widget.decoration,
      child: AxisFlex(
        axis: widget.axis,
        mainAxisSize: MainAxisSize.min,
        children: [
          iconButton(
            onPressed: deleteHandler,
            icon: deleteIcon(),
          ),
          for (final type in notesType) typeButton(type.type, type.icon),
          for (String color in notesColors) colorButton(color),
        ],
      ),
    );

    Widget operatorMenu = Container(
      // width: 48,
      decoration: widget.decoration,
      child: AxisFlex(
        axis: widget.axis,
        mainAxisSize: MainAxisSize.min,
        children: [
          // copy
          IconAndText(
            compact: true,
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.annoContent));
              AnxToast.show(L10n.of(context).notesPageCopied);
              widget.onClose();
            },
            icon: const Icon(EvaIcons.copy),
            text: L10n.of(context).contextMenuCopy,
          ),
          // Web search
          IconAndText(
            compact: true,
            onTap: () {
              final displayMode = Prefs().searchDisplayMode;
              final engine = Prefs().selectedSearchEngine;
              final query = widget.annoContent;

              switch (displayMode) {
                case SearchDisplayMode.popup:
                  widget.toggleSearchMenu(show: true, query: query);
                  break;
                case SearchDisplayMode.fullScreen:
                  widget.onClose();
                  launchUrl(
                    Uri.parse(engine.buildUrl(query)),
                    mode: LaunchMode.inAppWebView,
                  );
                  break;
                case SearchDisplayMode.external:
                  widget.onClose();
                  launchUrl(
                    Uri.parse(engine.buildUrl(query)),
                    mode: LaunchMode.externalApplication,
                  );
                  break;
              }
            },
            icon: const Icon(EvaIcons.globe),
            text: L10n.of(context).contextMenuSearch,
          ),
          // toggle translation menu
          IconAndText(
            compact: true,
            onTap: widget.toggleTranslationMenu,
            icon: const Icon(Icons.translate),
            text: L10n.of(context).contextMenuTranslate,
          ),
          // narrate
          IconAndText(
            compact: true,
            onTap: () async {
              widget.onClose();
              final playerState = epubPlayerKey.currentState;
              if (playerState == null) return;

              // Stop existing TTS playback if any
              await audioHandler.stop();

              // Now initialize TTS - it will use the current (updated) position
              await TtsHandler().init(
                () => playerState.initTts(fromCfi: widget.annoCfi),
                playerState.ttsNext,
                playerState.ttsPrev,
              );

              // Start TTS - audioHandler.play() will call TTS speak
              await audioHandler.play();
            },
            icon: const Icon(Icons.headphones),
            text: L10n.of(context).contextMenuNarrate,
          ),
          // edit note
          if (!widget.footnote)
            IconAndText(
              compact: true,
              onTap: () async {
                epubPlayerKey.currentState?.setSelectionClearLocked(true);
                await onColorSelected(annoColor, close: false);
                final targetId = noteId ?? widget.id;
                if (targetId != null) {
                  await widget.openReaderNoteMenu(targetId);
                } else {
                  widget.toggleReaderNoteMenu(show: true);
                }
              },
              icon: const Icon(EvaIcons.edit_2_outline),
              text: L10n.of(context).contextMenuWriteIdea,
            ),
          // AI chat
          if (EnvVar.enableAIFeature)
            IconAndText(
              compact: true,
              onTap: () {
                widget.onClose();
                final key = readingPageKey.currentState;
                if (key != null) {
                  key.showAiChat(
                    content: widget.annoContent,
                    sendImmediate: false,
                  );
                  key.aiChatKey.currentState?.inputController.text =
                      widget.annoContent;
                }
              },
              icon: const Icon(EvaIcons.message_circle_outline),
              text: L10n.of(context).navBarAI,
            ),
          // share
          IconAndText(
            compact: true,
            onTap: () {
              widget.onClose();
              ExcerptShareService.showShareExcerpt(
                context: context,
                bookTitle: epubPlayerKey.currentState!.book.title,
                author: epubPlayerKey.currentState!.book.author,
                excerpt: widget.annoContent,
                chapter: epubPlayerKey.currentState!.chapterTitle,
              );
            },
            icon: const Icon(EvaIcons.share_outline),
            text: L10n.of(context).contextMenuShare,
          ),
        ],
      ),
    );

    return Expanded(
      child: AxisFlex(
        reverse: widget.reverse,
        axis: flipAxis(widget.axis),
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AxisFlex(
            axis: flipAxis(widget.axis),
            reverse: widget.reverse,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                  scrollDirection: widget.axis, child: operatorMenu),
              const SizedBox.square(dimension: 10),
              if (!widget.footnote)
                SingleChildScrollView(
                  scrollDirection: widget.axis,
                  child: annotationMenu,
                ),
            ],
          ),
        ],
      ),
    );
  }
}
