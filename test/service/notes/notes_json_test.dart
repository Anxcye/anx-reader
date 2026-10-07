import 'package:anx_reader/models/book.dart';
import 'package:anx_reader/models/book_note.dart';
import 'package:anx_reader/service/notes/notes_json.dart';
import 'package:flutter_test/flutter_test.dart';

Book _book({
  String title = 'Demo',
  String author = 'Author',
  String? md5 = 'abc123',
  String filePath = 'file/demo.epub',
}) {
  return Book(
    id: 1,
    title: title,
    coverPath: '',
    filePath: filePath,
    lastReadPosition: '',
    readingPercentage: 0,
    author: author,
    isDeleted: false,
    rating: 0,
    md5: md5,
    createTime: DateTime.utc(2026, 1, 1),
    updateTime: DateTime.utc(2026, 1, 1),
  );
}

BookNote _note({
  required String cfi,
  String content = 'hello',
}) {
  return BookNote(
    bookId: 1,
    content: content,
    cfi: cfi,
    chapter: 'Ch1',
    type: 'highlight',
    color: 'FF0000',
    readerNote: 'note',
    createTime: DateTime.utc(2026, 2, 1),
    updateTime: DateTime.utc(2026, 2, 2),
  );
}

void main() {
  group('notes JSON match', () {
    test('exact md5 wins', () {
      final book = _book(md5: 'deadbeef');
      final fp = NotesJsonBookFingerprint(
        fileMd5: 'deadbeef',
        title: 'Other',
        author: 'X',
        fileSize: 10,
        fileName: 'a.epub',
      );
      expect(matchNotesJsonToBook(fp, book), NotesJsonMatchKind.exactMd5);
    });

    test('fuzzy title+author when md5 differs', () {
      final book = _book(title: ' Demo ', author: 'Author', md5: 'aaa');
      final fp = NotesJsonBookFingerprint(
        fileMd5: 'bbb',
        title: 'demo',
        author: 'author',
        fileSize: null,
        fileName: null,
      );
      expect(
          matchNotesJsonToBook(fp, book), NotesJsonMatchKind.fuzzyTitleAuthor);
    });

    test('refuse when neither md5 nor title+author match', () {
      final book = _book(title: 'A', author: 'B', md5: 'aaa');
      final fp = NotesJsonBookFingerprint(
        fileMd5: 'bbb',
        title: 'C',
        author: 'D',
        fileSize: null,
        fileName: null,
      );
      expect(matchNotesJsonToBook(fp, book), NotesJsonMatchKind.none);
    });
  });

  group('notes JSON round-trip fields', () {
    test('export payload encodes fingerprint and note fields', () {
      final book = _book();
      final notes = [_note(cfi: 'epubcfi(/6/2)', content: 'quote')];
      final payload = buildNotesJsonExport(book, notes);
      final decoded = NotesJsonPayload.decode(payload.encodePretty());

      expect(decoded.book.fileMd5, 'abc123');
      expect(decoded.book.title, 'Demo');
      expect(decoded.book.author, 'Author');
      expect(decoded.book.fileName, 'demo.epub');
      expect(decoded.notes, hasLength(1));
      expect(decoded.notes.single.cfi, 'epubcfi(/6/2)');
      expect(decoded.notes.single.chapter, 'Ch1');
      expect(decoded.notes.single.type, 'highlight');
      expect(decoded.notes.single.color, 'FF0000');
      expect(decoded.notes.single.content, 'quote');
      expect(decoded.notes.single.readerNote, 'note');
      expect(decoded.notes.single.createTime, DateTime.utc(2026, 2, 1));
      expect(decoded.notes.single.updateTime, DateTime.utc(2026, 2, 2));
    });
  });

  group('empty library upload gate', () {
    test('rejects upload when no non-deleted books', () {
      expect(
        shouldRejectEmptyLibraryUpload(
          nonDeletedBookCount: 0,
          isUploadDirection: true,
        ),
        isTrue,
      );
    });

    test('allows upload when library has books', () {
      expect(
        shouldRejectEmptyLibraryUpload(
          nonDeletedBookCount: 2,
          isUploadDirection: true,
        ),
        isFalse,
      );
    });

    test('does not reject non-upload directions', () {
      expect(
        shouldRejectEmptyLibraryUpload(
          nonDeletedBookCount: 0,
          isUploadDirection: false,
        ),
        isFalse,
      );
    });
  });
}
