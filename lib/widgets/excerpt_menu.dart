import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:flutter/material.dart';
import 'package:icons_plus/icons_plus.dart';

Widget excerptMenu(
    BuildContext context,
    String annoCfi,
    String annoContent,
    int? id,
    Function() onClose,
    ) {
  bool deleteConfirm = false;
  Icon deleteIcon() {
    return deleteConfirm
        ? const Icon(
      EvaIcons.close_circle,
      color: Colors.red,
    )
        : const Icon(Icons.delete);
  }

  String annoType = Prefs().annotationType;
  String annoColor = Prefs().annotationColor;

  final playerKey = epubPlayerKey.currentState!;

  void deleteHandler(StateSetter setState) {
    if (deleteConfirm) {
      if (id != null) {
        deleteBookNoteById(id);
        playerKey.webViewController.evaluateJavascript(
            source: 'removeAnnotations("$annoCfi", "highlight")');
      }
      onClose();
    } else {
      setState(() {
        deleteConfirm = true;
      });
    }
  }

  Future<void> onColorSelected(String color, {bool close = true}) async {
    Prefs().annotationColor = color;
    annoColor = color;
    if (id != null) {
      BookNote oldBookNote = await selectBookNoteById(id);
      playerKey.webViewController.evaluateJavascript(
          source:
          'removeAnnotations("${oldBookNote.cfi}", "${oldBookNote.type}")');
    }
    BookNote bookNote = BookNote(
      id: id,
      bookId: playerKey.widget.bookId,
      content: annoContent,
      cfi: annoCfi,
      chapter: playerKey.chapterTitle,
      type: annoType,
      color: annoColor,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
    );
    bookNote.setId(await insertBookNote(bookNote));
    playerKey.renderNote(bookNote);
    if (close) {
      onClose();
    }
  }

  void onTypeSelected(
      String type,
      ) {
    Prefs().annotationType = type;
    annoType = type;
    onColorSelected(annoColor, close: false);
  }

  return Container(
    decoration: BoxDecoration(
      color: Theme.of(context).scaffoldBackgroundColor,
      borderRadius: BorderRadius.circular(10),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.5),
          spreadRadius: 5,
          blurRadius: 7,
          offset: const Offset(0, 3),
        ),
      ],
    ),
    child: Row(children: [
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return IconButton(
              onPressed: () {
                deleteHandler(setState);
              },
              icon: deleteIcon());
        },
      ),
      IconButton(
        icon: Icon(
          Icons.format_underline,
          color: annoType == 'underline'
              ? Color(int.parse('0xff$annoColor'))
              : null,
        ),
        onPressed: () {
          onTypeSelected('underline');
        },
      ),
      IconButton(
        icon: Icon(
          AntDesign.highlight_outline,
          color: annoType == 'highlight'
              ? Color(int.parse('0xff$annoColor'))
              : null,
        ),
        onPressed: () {
          onTypeSelected('highlight');
        },
      ),
      const Divider(),
      IconButton(
        icon: Icon(Icons.circle, color: Color(int.parse('0x8866ccff'))),
        onPressed: () {
          onColorSelected('66ccff');
          onClose();
        },
      ),
      IconButton(
        icon: Icon(Icons.circle, color: Color(int.parse('0x88ff0000'))),
        onPressed: () {
          onColorSelected('ff0000');
          onClose();
        },
      ),
      IconButton(
        icon: Icon(Icons.circle, color: Color(int.parse('0x8800ff00'))),
        onPressed: () {
          onColorSelected('00ff00');
          onClose();
        },
      ),
      IconButton(
        icon: Icon(Icons.circle, color: Color(int.parse('0x88EB3BFF'))),
        onPressed: () {
          onColorSelected('EB3BFF');
          onClose();
        },
      ),
    ]),
  );
}
