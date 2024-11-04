import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/page/reading_page.dart';
import 'package:anx_reader/utils/toast/common.dart';
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

Widget excerptMenu(
  BuildContext context,
  String annoCfi,
  String annoContent,
  int? id,
  Function() onClose,
  bool footnote,
  BoxDecoration decoration,
  Function() toggleTranslationMenu,
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
        playerKey.removeAnnotation(annoCfi);
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
    BookNote bookNote = BookNote(
      id: id,
      bookId: playerKey.widget.book.id,
      content: annoContent,
      cfi: annoCfi,
      chapter: playerKey.chapterTitle,
      type: annoType,
      color: annoColor,
      createTime: DateTime.now(),
      updateTime: DateTime.now(),
    );
    bookNote.setId(await insertBookNote(bookNote));
    playerKey.addAnnotation(bookNote);
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
      for (Map<String, dynamic> type in notesType)
        typeButton(type['type'], type['icon']),
      for (String color in notesColors) colorButton(color),
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
          AnxToast.show(L10n.of(context).notes_page_copied);
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
      // toggle translation menu
      iconButton(
        icon: const Icon(Icons.translate),
        onPressed: () {
          toggleTranslationMenu();
        },
      ),
    ]),
  );

  return Expanded(
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        operatorMenu,
        if (!footnote) annotationMenu,
      ],
    ),
  );
}
