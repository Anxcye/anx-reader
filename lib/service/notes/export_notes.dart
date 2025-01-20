import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/utils/convert_string_to_uint8list.dart';
import 'package:anx_reader/utils/file_saver.dart';
import 'package:csv/csv.dart';
import 'package:fast_gbk/fast_gbk.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/services.dart';
import 'package:anx_reader/utils/toast/common.dart';

enum ExportType { copy, md, txt, csv }

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
        String exportContent = '${note.chapter}\n';

        if (note.content.isNotEmpty) {
          exportContent += '\t${note.content}\n';
        }

        if (note.readerNote != null && note.readerNote!.isNotEmpty) {
          exportContent += '\t\t${note.readerNote}\n';
        }

        return exportContent;
      }).join('\n\n');

      await Clipboard.setData(ClipboardData(text: notes));
      AnxToast.show(L10n.of(context).notes_page_copied);
      break;

    case ExportType.md:
      var notes = '# ${book.title}\n\n *${book.author}*\n\n';
      notes += notesList.map((note) {
        String exportContent = '## ${note.chapter}\n\n';
        if (note.content.isNotEmpty) {
          exportContent += '> ${note.content}\n\n';
        }

        if (note.readerNote != null && note.readerNote!.isNotEmpty) {
          exportContent += '${note.readerNote}\n\n';
        }

        return exportContent;
      }).join('');

      String? filePath = await fileSaver(
          bytes: convertStringToUint8List(notes),
          fileName: '${book.title.replaceAll('\n', ' ')}.md',
          mimeType: 'text/markdown');
      AnxToast.show('${L10n.of(context).notes_page_exported_to} $filePath');
      break;

    case ExportType.txt:
      var notes = notesList.map((note) {
        String exportContent = '${note.chapter}\n';

        if (note.content.isNotEmpty) {
          exportContent += '\t${note.content}\n';
        }

        if (note.readerNote != null && note.readerNote!.isNotEmpty) {
          exportContent += '\t\t${note.readerNote}\n';
        }
        return exportContent;
      }).join('\n\n');
      String? filePath = await fileSaver(
          bytes: convertStringToUint8List(notes),
          fileName: '${book.title}.txt',
          mimeType: 'text/plain');
      AnxToast.show('${L10n.of(context).notes_page_exported_to} $filePath');
      break;

    case ExportType.csv:
      List<List<dynamic>> list = List.from([
        [
          'Book',
          'Author',
          'Chapter',
          'Content',
          'Reader Note',
          'Type',
          'Color',
          'Create Time',
          'Update Time'
        ],
        ...notesList.map((note) {
          return List.from([
            book.title,
            book.author,
            note.chapter,
            note.content,
            note.readerNote,
            note.type,
            '#${note.color}',
            note.createTime!.toIso8601String(),
            note.updateTime.toIso8601String(),
          ]);
        })
      ]);

      final string = const ListToCsvConverter().convert(list);

      String? filePath = await fileSaver(
          bytes: Uint8List.fromList(gbk.encode(string)),
          fileName: '${book.title}.csv',
          mimeType: 'text/csv');

      AnxToast.show('${L10n.of(context).notes_page_exported_to} $filePath');
      break;
  }
}
