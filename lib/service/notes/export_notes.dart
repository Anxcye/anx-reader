import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:flutter/services.dart';

import '../../utils/get_download_path.dart';
import '../../utils/toast/common.dart';

enum ExportType { copy, md, txt }

Future<void> exportNotes(int bookId, ExportType exportType) async {
  var notesList = await selectBookNotesByBookId(bookId);
  var book = await selectBookById(bookId);
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
      // TODO l10n
      AnxToast.show('Notes copied to clipboard');
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
      // TODO l10n
      AnxToast.show('Exported to $savePath');
      break;

    case ExportType.txt:
      var notes = notesList.map((note) {
        return '${note.chapter}\n\n${note.content}\n\n';
      }).join('');
      final file = File('$savePath/${book.title}.txt');
      await file.writeAsString(notes);
      // TODO l10n
      AnxToast.show('Exported to $savePath');
      break;
  }
}
