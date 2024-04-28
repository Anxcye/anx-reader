import 'dart:io';

import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:flutter/services.dart';

import '../../utils/get_download_path.dart';

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
      break;

    case ExportType.md:
      var notes = '# ${book.title}\n\n *${book.author}*\n\n';
      notes += notesList.map((note) {
        return '## ${note.chapter}\n\n${note.content}\n\n';
      }).join('');
      final file = File('$savePath/${book.title.replaceAll('\n', ' ')}.md');

      // Create the file if it does not exist
      if (!await file.exists()) {
        await file.create(
            recursive:
                true); // Use recursive: true to create all directories in the path if they do not exist
      }

      // Write the file
      await file.writeAsString(notes);
      break;

    case ExportType.txt:
      var notes = notesList.map((note) {
        return '${note.chapter}\n\n${note.content}\n\n';
      }).join('');
      final file = File('$savePath/${book.title}.txt');
      await file.writeAsString(notes);
      break;
  }
}
