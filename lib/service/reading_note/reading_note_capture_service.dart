import 'package:anx_reader/dao/book_note.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/models/reading_note.dart';
import 'package:anx_reader/service/reading_note/reading_note_repository.dart';

class ReadingNoteCaptureService {
  ReadingNoteCaptureService({
    ReadingNoteRepository? repository,
    BookNoteDao? annotationDao,
  })  : _repository = repository ?? ReadingNoteRepository(),
        _annotationDao = annotationDao ?? bookNoteDao;

  final ReadingNoteRepository _repository;
  final BookNoteDao _annotationDao;

  Future<ReadingNoteDocument> capture({
    required int bookId,
    required String text,
    required String cfi,
    required String chapter,
    required String annotationType,
    required String annotationColor,
    required ReadingNoteCaptureKind kind,
    int? annotationId,
    String body = '',
    String? chapterHref,
  }) async {
    final now = DateTime.now();
    final existing = annotationId == null
        ? null
        : await _annotationDao.selectBookNoteById(annotationId);
    final annotation = BookNote(
      id: existing?.id ?? annotationId,
      bookId: existing?.bookId ?? bookId,
      content: existing?.content ?? text.trim(),
      cfi: existing?.cfi ?? cfi,
      chapter: existing?.chapter ?? chapter,
      type: existing?.type ?? annotationType,
      color: existing?.color ?? annotationColor,
      readerNote: body.trim().isEmpty ? existing?.readerNote : body.trim(),
      createTime: existing?.createTime ?? now,
      updateTime: now,
    );
    final savedId = await _annotationDao.save(annotation);
    annotation.id = savedId;
    return _repository.capture(
      annotation: annotation,
      kind: kind,
      body: body,
      chapterHref: chapterHref,
    );
  }

  Future<void> undo(String noteId) => _repository.deletePermanently(noteId);
}
