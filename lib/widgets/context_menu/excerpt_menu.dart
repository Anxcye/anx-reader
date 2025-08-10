import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:anx_reader/widgets/book_share/excerpt_share_service.dart';
import 'package:anx_reader/widgets/context_menu/reader_note_menu.dart';
import 'package:anx_reader/widgets/icon_and_text.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

List<String> notesColors = ['66CCFF', 'FF0000', '00FF00', 'EB3BFF', 'FFD700'];
List<Map<String, dynamic>> notesType = [
  {
    'type': 'highlight',
    'icon': AntDesign.highlight_outline,
  },
  {
    'type': 'underline',
    'icon': Icons.format_underline,
  },
];

class ExcerptMenu extends StatefulWidget {
  final String annoCfi;
  final String annoContent;
  final int? id;
  final Function() onClose;
  final bool footnote;
  final BoxDecoration decoration;
  final Function() toggleTranslationMenu;

  const ExcerptMenu({
    super.key,
    required this.annoCfi,
    required this.annoContent,
    this.id,
    required this.onClose,
    required this.footnote,
    required this.decoration,
    required this.toggleTranslationMenu,
  });

  @override
  ExcerptMenuState createState() => ExcerptMenuState();
}

class ExcerptMenuState extends State<ExcerptMenu> {
  bool deleteConfirm = false;
  late final GlobalKey<ReaderNoteMenuState> readerNoteMenuKey;
  int? noteId;

  @override
  initState() {
    super.initState();
    readerNoteMenuKey = GlobalKey<ReaderNoteMenuState>();
  }

  String annoType = Prefs().annotationType;
  String annoColor = Prefs().annotationColor;

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
        deleteBookNoteById(widget.id!);
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
    annoColor = color;

    BookNote? existingNote;
    DateTime? createTime;
    String? readerNote;

    if (widget.id != null) {
      try {
        existingNote = await selectBookNoteById(widget.id!);
        createTime = existingNote.createTime;
        readerNote = existingNote.readerNote;
      } catch (e) {
        createTime = DateTime.now();
      }
    } else {
      createTime = DateTime.now();
    }

    BookNote bookNote = BookNote(
      id: widget.id,
      bookId: epubPlayerKey.currentState!.widget.book.id,
      content: widget.annoContent,
      cfi: widget.annoCfi,
      chapter: epubPlayerKey.currentState!.chapterTitle,
      type: annoType,
      color: annoColor,
      readerNote: readerNote,
      createTime: createTime,
      updateTime: DateTime.now(),
    );
    noteId = await insertBookNote(bookNote);
    bookNote.setId(noteId!);
    epubPlayerKey.currentState!.addAnnotation(bookNote);
    if (close) {
      widget.onClose();
    }
  }

  void onTypeSelected(String type) {
    Prefs().annotationType = type;
    annoType = type;
    onColorSelected(annoColor, close: false);
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
      height: 48,
      decoration: widget.decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          iconButton(
            onPressed: deleteHandler,
            icon: deleteIcon(),
          ),
          for (Map<String, dynamic> type in notesType)
            typeButton(type['type'], type['icon']),
          for (String color in notesColors) colorButton(color),
        ],
      ),
    );

    Widget operatorMenu = Container(
      height: 48,
      decoration: widget.decoration,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // copy
          InkWell(
            onTap: () {
              Clipboard.setData(ClipboardData(text: widget.annoContent));
              AnxToast.show(L10n.of(context).notesPageCopied);
              widget.onClose();
            },
            child: IconAndText(
              icon: const Icon(EvaIcons.copy),
              text: L10n.of(context).contextMenuCopy,
            ),
          ),
          // Web search
          InkWell(
            onTap: () {
              widget.onClose();
              launchUrl(
                Uri.parse(
                    'https://www.bing.com/search?q=${widget.annoContent}'),
                mode: LaunchMode.externalApplication,
              );
            },
            child: IconAndText(
              icon: const Icon(EvaIcons.globe),
              text: L10n.of(context).contextMenuSearch,
            ),
          ),
          // toggle translation menu
          InkWell(
            onTap: widget.toggleTranslationMenu,
            child: IconAndText(
              icon: const Icon(Icons.translate),
              text: L10n.of(context).contextMenuTranslate,
            ),
          ),
          // edit note
          if (!widget.footnote)
            InkWell(
              onTap: () async {
                await onColorSelected(annoColor, close: false);
                // update that noteId is not null
                setState(() {});
                await readerNoteMenuKey.currentState!.showNoteDialog(noteId!);
              },
              child: IconAndText(
                icon: const Icon(EvaIcons.edit_2_outline),
                text: L10n.of(context).contextMenuWriteIdea,
              ),
            ),
          // AI chat
          InkWell(
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
            child: IconAndText(
              icon: const Icon(EvaIcons.message_circle_outline),
              text: L10n.of(context).aiChat,
            ),
          ),
          // share
          InkWell(
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
            child: IconAndText(
              icon: const Icon(EvaIcons.share_outline),
              text: L10n.of(context).contextMenuShare,
            ),
          ),
        ],
      ),
    );

    return Expanded(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SingleChildScrollView(
                  scrollDirection: Axis.horizontal, child: operatorMenu),
              const SizedBox(height: 10),
              if (!widget.footnote)
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: annotationMenu,
                ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              ReaderNoteMenu(
                key: readerNoteMenuKey,
                noteId: widget.id,
                decoration: widget.decoration,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
