import 'package:anx_reader/dao/book.dart';
import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/dao/reading_note.dart';
import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:uuid/uuid.dart';

class ReadingNoteQuery {
  const ReadingNoteQuery({
    this.bookId,
    this.search = '',
    this.status,
    this.captureKind,
    this.tagId,
    this.sourceType,
    this.activeReadingOnly = false,
    this.favoritesOnly = false,
  });
  final int? bookId;
  final String search;
  final ReadingNoteStatus? status;
  final ReadingNoteCaptureKind? captureKind;
  final String? tagId;
  final ReadingNoteSourceType? sourceType;
  final bool activeReadingOnly;
  final bool favoritesOnly;
}

class ReadingNoteRepository {
  ReadingNoteRepository({
    ReadingNoteDao? dao,
    BookNoteDao? annotationDao,
    BookDao? books,
    Uuid? uuid,
  })  : _dao = dao ?? readingNoteDaoInstance,
        _annotationDao = annotationDao ?? bookNoteDao,
        _books = books ?? bookDao,
        _uuid = uuid ?? const Uuid();

  final ReadingNoteDao _dao;
  final BookNoteDao _annotationDao;
  final BookDao _books;
  final Uuid _uuid;

  Future<List<ReadingNoteListItem>> list(ReadingNoteQuery query) async {
    final books = await _books.selectAllBooks();
    final bookMap = {for (final book in books) book.id: book};
    final notes = await _dao.notes(bookId: query.bookId, status: query.status);
    final documents = await Future.wait(notes.map(document));
    final mappedIds = documents
        .expand((item) => item.sources)
        .where((source) => source.type == ReadingNoteSourceType.annotation)
        .map((source) => int.tryParse(source.sourceRef))
        .whereType<int>()
        .toSet();
    final legacy = <BookNote>[];
    final targetBooks = query.bookId == null
        ? books
        : books.where((book) => book.id == query.bookId);
    if (query.status == null || query.status != ReadingNoteStatus.trashed) {
      for (final book in targetBooks) {
        legacy.addAll((await _annotationDao.selectBookNotesByBookId(book.id))
            .where((note) => note.id != null && !mappedIds.contains(note.id)));
      }
    }
    final items = <ReadingNoteListItem>[
      for (final doc in documents)
        if (bookMap[doc.note.bookId] case final Book book)
          ReadingNoteListItem(document: doc, book: book),
      for (final annotation in legacy)
        if (bookMap[annotation.bookId] case final Book book)
          ReadingNoteListItem(legacyAnnotation: annotation, book: book),
    ];
    final search = query.search.trim().toLowerCase();
    final filtered = items.where((item) {
      final doc = item.document;
      if (query.captureKind != null &&
          doc?.note.captureKind != query.captureKind) {
        return false;
      }
      if (query.favoritesOnly && doc?.note.isFavorite != true) {
        return false;
      }
      if (query.tagId != null &&
          doc?.tags.any((tag) => tag.id == query.tagId) != true) {
        return false;
      }
      if (query.sourceType != null &&
          doc?.sources.any((source) => source.type == query.sourceType) !=
              true) {
        return false;
      }
      if (query.activeReadingOnly &&
          doc?.sources.any((source) => const {
                    ReadingNoteSourceType.difficulty,
                    ReadingNoteSourceType.aiSession,
                    ReadingNoteSourceType.memoryTopic,
                    ReadingNoteSourceType.knowledgeCard,
                    ReadingNoteSourceType.guide,
                    ReadingNoteSourceType.quiz,
                  }.contains(source.type)) !=
              true) {
        return false;
      }
      if (search.isEmpty) return true;
      return [
        item.title,
        item.body,
        item.quote,
        item.chapter,
        item.book.title,
        ...?doc?.tags.map((tag) => tag.name),
      ].any((value) => value.toLowerCase().contains(search));
    }).toList();
    filtered.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return filtered;
  }

  Future<ReadingNoteDocument> document(ReadingNote note) async =>
      _documentWithAvailability(note);

  Future<ReadingNoteDocument> _documentWithAvailability(
      ReadingNote note) async {
    final sources = await _dao.sources(note.id);
    final checked = await Future.wait(sources.map((source) async {
      if (source.type != ReadingNoteSourceType.annotation) return source;
      final id = int.tryParse(source.sourceRef);
      if (id == null) return source.copyWith(isAvailable: false);
      try {
        await _annotationDao.selectBookNoteById(id);
        return source;
      } on StateError {
        return source.copyWith(isAvailable: false);
      }
    }));
    return ReadingNoteDocument(
      note: note,
      blocks: await _dao.blocks(note.id),
      sources: checked,
      tags: await _dao.tags(noteId: note.id),
    );
  }

  Future<ReadingNoteDocument> capture({
    required BookNote annotation,
    required ReadingNoteCaptureKind kind,
    String body = '',
    String? chapterHref,
  }) async {
    if (annotation.id == null) throw ArgumentError('Annotation must be saved');
    final existing = await _dao.mappedAnnotationId(annotation.id!);
    if (existing != null) {
      final note = await _dao.note(existing);
      if (note != null) return document(note);
    }
    final now = DateTime.now().millisecondsSinceEpoch;
    final id = _uuid.v4();
    final note = ReadingNote(
      id: id,
      bookId: annotation.bookId,
      title: '',
      status: kind == ReadingNoteCaptureKind.later
          ? ReadingNoteStatus.inbox
          : ReadingNoteStatus.active,
      captureKind: kind,
      isFavorite: kind == ReadingNoteCaptureKind.keyPoint,
      createdAt: now,
      updatedAt: now,
    );
    final createdDocument = ReadingNoteDocument(
      note: note,
      blocks: [
        ReadingNoteBlock(
          id: _uuid.v4(),
          noteId: id,
          type: ReadingNoteBlockType.quote,
          content: annotation.content,
          sortOrder: 0,
          origin: ReadingNoteBlockOrigin.source,
          createdAt: now,
          updatedAt: now,
        ),
        ReadingNoteBlock(
          id: _uuid.v4(),
          noteId: id,
          type: ReadingNoteBlockType.text,
          content: body.isEmpty ? annotation.readerNote ?? '' : body,
          sortOrder: 1,
          origin: ReadingNoteBlockOrigin.user,
          createdAt: now,
          updatedAt: now,
        ),
      ],
      sources: [
        ReadingNoteSource(
          noteId: id,
          type: ReadingNoteSourceType.annotation,
          sourceRef: annotation.id!.toString(),
          chapterHref: chapterHref,
          chapterTitle: annotation.chapter,
          cfi: annotation.cfi,
          textSnapshot: annotation.content,
          createdAt: now,
        ),
      ],
    );
    await _dao.createDocument(createdDocument);
    return createdDocument;
  }

  Future<ReadingNoteDocument> mapLegacy(BookNote annotation) => capture(
        annotation: annotation,
        kind: ReadingNoteCaptureKind.highlight,
      );

  Future<ReadingNoteDocument> save({
    required ReadingNoteDocument currentDocument,
    required String title,
    required String body,
    required ReadingNoteStatus status,
    required bool favorite,
    required List<String> tagNames,
    bool recordRevision = false,
  }) async {
    final now = DateTime.now().millisecondsSinceEpoch;
    final updated = currentDocument.note.copyWith(
      title: title.trim(),
      status: status,
      isFavorite: favorite,
      updatedAt: now,
      deletedAt: status == ReadingNoteStatus.trashed ? now : null,
      clearDeletedAt: status != ReadingNoteStatus.trashed,
    );
    final currentText = currentDocument.blocks
        .where((block) => block.type == ReadingNoteBlockType.text)
        .firstOrNull;
    final textBlock = ReadingNoteBlock(
      id: currentText?.id ?? _uuid.v4(),
      noteId: updated.id,
      type: ReadingNoteBlockType.text,
      content: body.trim(),
      sortOrder: 1,
      origin: ReadingNoteBlockOrigin.user,
      createdAt: currentText?.createdAt ?? now,
      updatedAt: now,
    );
    final tags = tagNames
        .map((name) => name.trim())
        .where((name) => name.isNotEmpty)
        .map((name) {
      final normalized = name.toLowerCase();
      return ReadingNoteTag(
        id: 'tag-${_uuid.v5(Namespace.url.value, normalized)}',
        name: name,
        normalizedName: normalized,
        createdAt: now,
        updatedAt: now,
      );
    }).toList();
    final annotationId = currentDocument.sources
        .where((source) => source.type == ReadingNoteSourceType.annotation)
        .map((source) => int.tryParse(source.sourceRef))
        .whereType<int>()
        .firstOrNull;
    await _dao.saveDocument(
      note: updated,
      textBlock: textBlock,
      tags: tags,
      revision: recordRevision
          ? ReadingNoteRevision(
              id: _uuid.v4(),
              noteId: updated.id,
              title: updated.title,
              body: textBlock.content,
              tags: tags.map((tag) => tag.name).toList(),
              status: updated.status,
              createdAt: now,
            )
          : null,
      annotationId: annotationId,
    );
    return document(updated);
  }

  Future<void> trash(ReadingNote note) => _dao.updateNote(note.copyWith(
      status: ReadingNoteStatus.trashed,
      deletedAt: DateTime.now().millisecondsSinceEpoch,
      updatedAt: DateTime.now().millisecondsSinceEpoch));
  Future<void> restore(ReadingNote note) => _dao.updateNote(note.copyWith(
      status: ReadingNoteStatus.active,
      clearDeletedAt: true,
      updatedAt: DateTime.now().millisecondsSinceEpoch));
  Future<void> deletePermanently(String id) => _dao.deletePermanently(id);
  Future<List<ReadingNoteTag>> tags() => _dao.tags();
  Future<List<Book>> books() => _books.selectAllBooks();
  Future<List<ReadingNoteRevision>> revisions(String noteId) =>
      _dao.revisions(noteId);

  Future<ReadingNoteDocument> deleteAiBlock(
      ReadingNoteDocument document, ReadingNoteBlock block) async {
    if (block.type != ReadingNoteBlockType.ai ||
        block.noteId != document.note.id) {
      throw ArgumentError('Expected an AI block owned by this note');
    }
    await _dao.deleteBlock(block.id);
    return this.document(document.note);
  }

  Future<ReadingNoteDocument> convertAiBlockToBody(
      ReadingNoteDocument document, ReadingNoteBlock block) async {
    if (block.type != ReadingNoteBlockType.ai ||
        block.noteId != document.note.id) {
      throw ArgumentError('Expected an AI block owned by this note');
    }
    final body = [document.body.trim(), block.content.trim()]
        .where((value) => value.isNotEmpty)
        .join('\n\n');
    final saved = await save(
      currentDocument: document,
      title: document.note.title,
      body: body,
      status: document.note.status,
      favorite: document.note.isFavorite,
      tagNames: document.tags.map((tag) => tag.name).toList(),
      recordRevision: true,
    );
    final batchId = block.metadata['batchId']?.toString();
    if (batchId?.isNotEmpty == true) {
      await _dao.saveSources([
        ReadingNoteSource(
          noteId: document.note.id,
          type: ReadingNoteSourceType.aiSession,
          sourceRef: 'note-ai:$batchId',
          textSnapshot: block.content,
          metadata: block.metadata,
          createdAt: DateTime.now().millisecondsSinceEpoch,
        ),
      ]);
    }
    await _dao.deleteBlock(block.id);
    return this.document(saved.note);
  }
}

extension _FirstOrNull<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
