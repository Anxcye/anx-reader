import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/localization_extension.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/toast/common.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:icons_plus/icons_plus.dart';
import 'package:url_launcher/url_launcher.dart';

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

  List<String> colors = ['66ccff', 'FF0000', '00FF00', 'EB3BFF', 'FFD700'];

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

  BoxDecoration decoration = BoxDecoration(
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
  );

  Widget annotationMenu = Container(
    height: 48,
    decoration: decoration,
    child: Row(children: [
      StatefulBuilder(
        builder: (BuildContext context, StateSetter setState) {
          return iconButton(
              onPressed: () {
                deleteHandler(setState);
              },
              icon: deleteIcon());
        },
      ),
      typeButton('underline', Icons.format_underline),
      typeButton('highlight', AntDesign.highlight_outline),
      for (String color in colors) colorButton(color),
    ]),
  );

  Widget operatorMenu = Container(
    height: 48,
    decoration: decoration,
    child: Row(children: [
      // copy
      iconButton(
        icon: const Icon(EvaIcons.copy),
        onPressed: () {
          Clipboard.setData(ClipboardData(text: annoContent));
          AnxToast.show(context.notesPageCopied);
          onClose();
        },
      ),
      // Web search
      iconButton(
        icon: const Icon(EvaIcons.globe),
        onPressed: () {
          onClose();
          // open browser
          launchUrl(Uri.parse('https://www.bing.com/search?q=$annoContent'),
              mode: LaunchMode.externalApplication);
        },
      ),
    ]),
  );

  return Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      operatorMenu,
      annotationMenu,
    ],
  );
}
