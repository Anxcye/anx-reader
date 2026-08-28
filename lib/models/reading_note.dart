import 'dart:convert';

import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';

enum ReadingNoteStatus { inbox, active, archived, trashed }

enum ReadingNoteCaptureKind {
  highlight,
  keyPoint,
  question,
  disagree,
  actionable,
  later,
  manual,
}

enum ReadingNoteBlockType { quote, text, checklist, ai }

enum ReadingNoteBlockOrigin { user, source, ai }

enum ReadingNoteSourceType {
  annotation,
  difficulty,
  aiSession,
  memoryTopic,
  knowledgeCard,
  guide,
  quiz,
}

class ReadingNote {
  const ReadingNote({
    required this.id,
    required this.bookId,
    required this.title,
    required this.status,
    required this.captureKind,
    required this.isFavorite,
    required this.createdAt,
    required this.updatedAt,
    this.deletedAt,
  });

  final String id;
  final int bookId;
  final String title;
  final ReadingNoteStatus status;
  final ReadingNoteCaptureKind captureKind;
  final bool isFavorite;
  final int createdAt;
  final int updatedAt;
  final int? deletedAt;

  ReadingNote copyWith({
    String? title,
    ReadingNoteStatus? status,
    ReadingNoteCaptureKind? captureKind,
    bool? isFavorite,
    int? updatedAt,
    int? deletedAt,
    bool clearDeletedAt = false,
  }) =>
      ReadingNote(
        id: id,
        bookId: bookId,
        title: title ?? this.title,
        status: status ?? this.status,
        captureKind: captureKind ?? this.captureKind,
        isFavorite: isFavorite ?? this.isFavorite,
        createdAt: createdAt,
        updatedAt: updatedAt ?? this.updatedAt,
        deletedAt: clearDeletedAt ? null : deletedAt ?? this.deletedAt,
      );

  Map<String, Object?> toDb() => {
        'id': id,
        'book_id': bookId,
        'title': title,
        'status': status.name,
        'capture_kind': captureKind.name,
        'is_favorite': isFavorite ? 1 : 0,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'deleted_at': deletedAt,
      };

  factory ReadingNote.fromDb(Map<String, dynamic> row) => ReadingNote(
        id: row['id'].toString(),
        bookId: row['book_id'] as int,
        title: row['title']?.toString() ?? '',
        status: ReadingNoteStatus.values.byName(row['status'].toString()),
        captureKind: ReadingNoteCaptureKind.values
            .byName(row['capture_kind'].toString()),
        isFavorite: row['is_favorite'] == 1,
        createdAt: row['created_at'] as int,
        updatedAt: row['updated_at'] as int,
        deletedAt: row['deleted_at'] as int?,
      );
}

class ReadingNoteBlock {
  const ReadingNoteBlock({
    required this.id,
    required this.noteId,
    required this.type,
    required this.content,
    required this.sortOrder,
    required this.origin,
    required this.createdAt,
    required this.updatedAt,
    this.metadata = const {},
  });

  final String id;
  final String noteId;
  final ReadingNoteBlockType type;
  final String content;
  final int sortOrder;
  final ReadingNoteBlockOrigin origin;
  final int createdAt;
  final int updatedAt;
  final Map<String, dynamic> metadata;

  Map<String, Object?> toDb() => {
        'id': id,
        'note_id': noteId,
        'block_type': type.name,
        'content': content,
        'sort_order': sortOrder,
        'origin': origin.name,
        'created_at': createdAt,
        'updated_at': updatedAt,
        'metadata': jsonEncode(metadata),
      };

  factory ReadingNoteBlock.fromDb(Map<String, dynamic> row) => ReadingNoteBlock(
        id: row['id'].toString(),
        noteId: row['note_id'].toString(),
        type: ReadingNoteBlockType.values.byName(row['block_type'].toString()),
        content: row['content']?.toString() ?? '',
        sortOrder: row['sort_order'] as int,
        origin: ReadingNoteBlockOrigin.values.byName(row['origin'].toString()),
        createdAt: row['created_at'] as int,
        updatedAt: row['updated_at'] as int,
        metadata: _decodeMap(row['metadata']),
      );
}

class ReadingNoteSource {
  const ReadingNoteSource({
    required this.noteId,
    required this.type,
    required this.sourceRef,
    this.chapterHref,
    this.chapterTitle,
    this.cfi,
    required this.textSnapshot,
    this.metadata = const {},
    required this.createdAt,
    this.isAvailable = true,
  });

  final String noteId;
  final ReadingNoteSourceType type;
  final String sourceRef;
  final String? chapterHref;
  final String? chapterTitle;
  final String? cfi;
  final String textSnapshot;
  final Map<String, dynamic> metadata;
  final int createdAt;
  final bool isAvailable;

  ReadingNoteSource copyWith({bool? isAvailable}) => ReadingNoteSource(
        noteId: noteId,
        type: type,
        sourceRef: sourceRef,
        chapterHref: chapterHref,
        chapterTitle: chapterTitle,
        cfi: cfi,
        textSnapshot: textSnapshot,
        metadata: metadata,
        createdAt: createdAt,
        isAvailable: isAvailable ?? this.isAvailable,
      );

  Map<String, Object?> toDb() => {
        'note_id': noteId,
        'source_type': type.name,
        'source_ref': sourceRef,
        'chapter_href': chapterHref,
        'chapter_title': chapterTitle,
        'cfi': cfi,
        'text_snapshot': textSnapshot,
        'metadata': jsonEncode(metadata),
        'created_at': createdAt,
      };

  factory ReadingNoteSource.fromDb(Map<String, dynamic> row) =>
      ReadingNoteSource(
        noteId: row['note_id'].toString(),
        type:
            ReadingNoteSourceType.values.byName(row['source_type'].toString()),
        sourceRef: row['source_ref'].toString(),
        chapterHref: row['chapter_href']?.toString(),
        chapterTitle: row['chapter_title']?.toString(),
        cfi: row['cfi']?.toString(),
        textSnapshot: row['text_snapshot']?.toString() ?? '',
        metadata: _decodeMap(row['metadata']),
        createdAt: row['created_at'] as int,
      );
}

class ReadingNoteTag {
  const ReadingNoteTag({
    required this.id,
    required this.name,
    required this.normalizedName,
    required this.createdAt,
    required this.updatedAt,
  });
  final String id;
  final String name;
  final String normalizedName;
  final int createdAt;
  final int updatedAt;

  Map<String, Object?> toDb() => {
        'id': id,
        'name': name,
        'normalized_name': normalizedName,
        'created_at': createdAt,
        'updated_at': updatedAt,
      };

  factory ReadingNoteTag.fromDb(Map<String, dynamic> row) => ReadingNoteTag(
        id: row['id'].toString(),
        name: row['name'].toString(),
        normalizedName: row['normalized_name'].toString(),
        createdAt: row['created_at'] as int,
        updatedAt: row['updated_at'] as int,
      );
}

class ReadingNoteRevision {
  const ReadingNoteRevision({
    required this.id,
    required this.noteId,
    required this.title,
    required this.body,
    required this.tags,
    required this.status,
    required this.createdAt,
  });
  final String id;
  final String noteId;
  final String title;
  final String body;
  final List<String> tags;
  final ReadingNoteStatus status;
  final int createdAt;

  Map<String, Object?> toDb() => {
        'id': id,
        'note_id': noteId,
        'title': title,
        'body': body,
        'tags': jsonEncode(tags),
        'status': status.name,
        'created_at': createdAt,
      };

  factory ReadingNoteRevision.fromDb(Map<String, dynamic> row) =>
      ReadingNoteRevision(
        id: row['id'].toString(),
        noteId: row['note_id'].toString(),
        title: row['title']?.toString() ?? '',
        body: row['body']?.toString() ?? '',
        tags: _decodeList(row['tags']),
        status: ReadingNoteStatus.values.byName(row['status'].toString()),
        createdAt: row['created_at'] as int,
      );
}

class ReadingNoteDocument {
  const ReadingNoteDocument({
    required this.note,
    this.blocks = const [],
    this.sources = const [],
    this.tags = const [],
  });
  final ReadingNote note;
  final List<ReadingNoteBlock> blocks;
  final List<ReadingNoteSource> sources;
  final List<ReadingNoteTag> tags;

  String get body => blocks
      .where((block) => block.type == ReadingNoteBlockType.text)
      .map((block) => block.content)
      .join('\n');
  String get quote => blocks
      .where((block) => block.type == ReadingNoteBlockType.quote)
      .map((block) => block.content)
      .join('\n');
}

class ReadingNoteListItem {
  const ReadingNoteListItem({
    this.document,
    this.legacyAnnotation,
    required this.book,
  }) : assert(document != null || legacyAnnotation != null);

  final ReadingNoteDocument? document;
  final BookNote? legacyAnnotation;
  final Book book;
  bool get isLegacy => document == null;
  String get identity =>
      document?.note.id ?? 'annotation-${legacyAnnotation!.id}';
  String get title => document?.note.title ?? '';
  String get body => document?.body ?? legacyAnnotation?.readerNote ?? '';
  String get quote => document?.quote ?? legacyAnnotation?.content ?? '';
  String get chapter =>
      document?.sources.firstOrNull?.chapterTitle ??
      legacyAnnotation?.chapter ??
      '';
  String? get cfi =>
      document?.sources.firstOrNull?.cfi ?? legacyAnnotation?.cfi;
  int get updatedAt =>
      document?.note.updatedAt ??
      legacyAnnotation?.updateTime.millisecondsSinceEpoch ??
      0;
}

Map<String, dynamic> _decodeMap(Object? value) {
  if (value is! String || value.isEmpty) return const {};
  final decoded = jsonDecode(value);
  return decoded is Map ? Map<String, dynamic>.from(decoded) : const {};
}

List<String> _decodeList(Object? value) {
  if (value is! String || value.isEmpty) return const [];
  final decoded = jsonDecode(value);
  return decoded is List
      ? decoded.map((item) => item.toString()).toList(growable: false)
      : const [];
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
