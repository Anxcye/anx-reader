
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/utils/convert_string_to_uint8list.dart';
import 'package:anx_reader/utils/file_saver.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:anx_reader/utils/toast/common.dart';

enum ExportType { copy, md, txt }

Future<void> exportNotes(
    Book book, List<BookNote> notesList, ExportType exportType) async {
  BuildContext context = navigatorKey.currentContext!;
  if (notesList.isEmpty) {
    return;
  }

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

      String? filePath = await fileSaver(
          bytes: convertStringToUint8List(notes),
          fileName: '${book.title.replaceAll('\n', ' ')}.md',
          mimeType: 'text/markdown');
      AnxToast.show('${L10n.of(context).notes_page_exported_to} $filePath');
      break;

    case ExportType.txt:
      var notes = notesList.map((note) {
        return '${note.chapter}\n\n${note.content}\n\n';
      }).join('');
      String? filePath = await fileSaver(
          bytes: convertStringToUint8List(notes),
          fileName: '${book.title}.txt',
          mimeType: 'text/plain');
      AnxToast.show('${L10n.of(context).notes_page_exported_to} $filePath');
      break;
  }
}
