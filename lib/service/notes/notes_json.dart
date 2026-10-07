import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:path/path.dart' as p;

/// Match result when importing notes JSON against a target book.
enum NotesJsonMatchKind {
  /// Fingerprint fileMd5 equals the target book's md5.
  exactMd5,

  /// Title + author match (case-insensitive trim) but md5 does not.
  fuzzyTitleAuthor,

  /// No usable match — refuse import.
  none,
}

class NotesJsonBookFingerprint {
  const NotesJsonBookFingerprint({
    required this.fileMd5,
    required this.title,
    required this.author,
    required this.fileSize,
    required this.fileName,
  });

  final String? fileMd5;
  final String title;
  final String author;
  final int? fileSize;
  final String? fileName;

  Map<String, dynamic> toJson() => {
        'fileMd5': fileMd5,
        'title': title,
        'author': author,
        'fileSize': fileSize,
        'fileName': fileName,
      };

  factory NotesJsonBookFingerprint.fromJson(Map<String, dynamic> json) {
    return NotesJsonBookFingerprint(
      fileMd5: json['fileMd5'] as String?,
      title: (json['title'] as String?) ?? '',
      author: (json['author'] as String?) ?? '',
      fileSize: (json['fileSize'] as num?)?.toInt(),
      fileName: json['fileName'] as String?,
    );
  }

  factory NotesJsonBookFingerprint.fromBook(Book book) {
    int? size;
    try {
      final file = File(book.fileFullPath);
      if (file.existsSync()) {
        size = file.lengthSync();
      }
    } catch (_) {
      size = null;
    }
    final name = book.filePath.isEmpty ? null : p.basename(book.filePath);
    return NotesJsonBookFingerprint(
      fileMd5: book.md5,
      title: book.title,
      author: book.author,
      fileSize: size,
      fileName: name,
    );
  }
}

class NotesJsonPayload {
  const NotesJsonPayload({
    required this.version,
    required this.book,
    required this.notes,
  });

  final int version;
  final NotesJsonBookFingerprint book;
  final List<BookNote> notes;

  Map<String, dynamic> toJson() => {
        'version': version,
        'book': book.toJson(),
        'notes': notes.map(notesJsonNoteToMap).toList(),
      };

  String encodePretty() =>
      const JsonEncoder.withIndent('  ').convert(toJson());

  static NotesJsonPayload decode(String raw) {
    final decoded = jsonDecode(raw);
    if (decoded is! Map<String, dynamic>) {
      throw const FormatException('Notes JSON root must be an object');
    }
    final bookRaw = decoded['book'];
    if (bookRaw is! Map<String, dynamic>) {
      throw const FormatException('Notes JSON missing book fingerprint');
    }
    final notesRaw = decoded['notes'];
    if (notesRaw is! List) {
      throw const FormatException('Notes JSON missing notes array');
    }
    final notes = <BookNote>[];
    for (final item in notesRaw) {
      if (item is Map<String, dynamic>) {
        notes.add(notesJsonNoteFromMap(item, bookId: 0));
      }
    }
    return NotesJsonPayload(
      version: (decoded['version'] as num?)?.toInt() ?? 1,
      book: NotesJsonBookFingerprint.fromJson(bookRaw),
      notes: notes,
    );
  }
}

Map<String, dynamic> notesJsonNoteToMap(BookNote note) => {
      'cfi': note.cfi,
      'chapter': note.chapter,
      'type': note.type,
      'color': note.color,
      'content': note.content,
      'readerNote': note.readerNote,
      'createTime': note.createTime?.toIso8601String(),
      'updateTime': note.updateTime.toIso8601String(),
    };

BookNote notesJsonNoteFromMap(Map<String, dynamic> map, {required int bookId}) {
  final createTimeString = map['createTime'] as String?;
  final updateTimeString = map['updateTime'] as String?;
  var color = (map['color'] as String?) ?? '';
  if (color.startsWith('#')) {
    color = color.substring(1);
  }
  return BookNote(
    bookId: bookId,
    content: (map['content'] as String?) ?? '',
    cfi: (map['cfi'] as String?) ?? '',
    chapter: (map['chapter'] as String?) ?? '',
    type: (map['type'] as String?) ?? 'highlight',
    color: color,
    readerNote: map['readerNote'] as String?,
    createTime:
        createTimeString != null ? DateTime.tryParse(createTimeString) : null,
    updateTime: updateTimeString != null
        ? (DateTime.tryParse(updateTimeString) ?? DateTime.now())
        : DateTime.now(),
  );
}

NotesJsonPayload buildNotesJsonExport(Book book, List<BookNote> notes) {
  return NotesJsonPayload(
    version: 1,
    book: NotesJsonBookFingerprint.fromBook(book),
    notes: notes,
  );
}

/// Pure match helper for tests and import UI.
NotesJsonMatchKind matchNotesJsonToBook(
  NotesJsonBookFingerprint fingerprint,
  Book target,
) {
  final fpMd5 = fingerprint.fileMd5?.trim();
  final bookMd5 = target.md5?.trim();
  if (fpMd5 != null &&
      fpMd5.isNotEmpty &&
      bookMd5 != null &&
      bookMd5.isNotEmpty &&
      fpMd5 == bookMd5) {
    return NotesJsonMatchKind.exactMd5;
  }

  final fpTitle = fingerprint.title.trim().toLowerCase();
  final fpAuthor = fingerprint.author.trim().toLowerCase();
  final bookTitle = target.title.trim().toLowerCase();
  final bookAuthor = target.author.trim().toLowerCase();
  if (fpTitle.isNotEmpty &&
      bookTitle.isNotEmpty &&
      fpTitle == bookTitle &&
      fpAuthor == bookAuthor) {
    return NotesJsonMatchKind.fuzzyTitleAuthor;
  }
  return NotesJsonMatchKind.none;
}

/// Whether an empty local library should abort a database upload.
bool shouldRejectEmptyLibraryUpload({
  required int nonDeletedBookCount,
  required bool isUploadDirection,
}) {
  return isUploadDirection && nonDeletedBookCount <= 0;
}
