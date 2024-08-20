import 'dart:io';

import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';

import '../../utils/get_download_path.dart';
import '../../utils/toast/common.dart';

enum ExportType { copy, md, txt }

Future<void> exportNotes(Book book, List<BookNote> notesList, ExportType exportType) async {
  BuildContext context = navigatorKey.currentContext!;
  if (notesList.isEmpty) {
    return;
  }

  var savePath = '';
  if (exportType != ExportType.copy) savePath = await getDownloadPath();

  switch (exportType) {
    case ExportType.copy:
      var notes = '${book.title}\n\t${book.author}\n\n';
      notes += notesList.map((note) {
        return '${note.chapter}\n\t${note.content}';
      }).join('\n');
      await Clipboard.setData(ClipboardData(text: notes));
      AnxToast.show(L10n.of(context).notes_page_copied);
      break;

    case ExportType.md:
      var notes = '# ${book.title}\n\n *${book.author}*\n\n';
      notes += notesList.map((note) {
        return '## ${note.chapter}\n\n${note.content}\n\n';
      }).join('');
      final file = File('$savePath/${book.title.replaceAll('\n', ' ')}.md');

      if (!await file.exists()) {
        await file.create(recursive: true);
      }

      await file.writeAsString(notes);
      AnxToast.show('${L10n.of(context).notes_page_exported_to} $savePath');
      break;

    case ExportType.txt:
      var notes = notesList.map((note) {
        return '${note.chapter}\n\n${note.content}\n\n';
      }).join('');
      final file = File('$savePath/${book.title}.txt');
      await file.writeAsString(notes);
      AnxToast.show('${L10n.of(context).notes_page_exported_to} $savePath');
      break;
  }
}
