import 'package:anx_reader/models/book_materials.dart';
import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/service/ai/reading_memory_projection.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ReadingMemorySource source(String cfi, {int bookId = 1}) =>
      ReadingMemorySource(
          id: 'source',
          bookId: bookId,
          type: ReadingMemorySourceType.difficulty,
          sourceRef: 'question',
          chapterHref: 'same.xhtml',
          cfi: cfi,
          text: 'My reading question',
          contentHash: 'hash',
          createdAt: 1);

  const materials = BookMaterialsSnapshot(
      bookId: 1,
      visibleAtProgress: .4,
      sourceBoundaries: {
        'epubcfi(/6/2)': .2,
        'epubcfi(/6/4)': .7,
        'same.xhtml': .1
      });

  test('memory sources require an exact known source boundary', () {
    expect(
        ReadingMemoryProjection.sourceBoundary(
            source('epubcfi(/6/2)'), materials),
        .2);
    expect(
        ReadingMemoryProjection.sourceBoundary(
            source('epubcfi(/6/4)'), materials),
        isNull);
    expect(
        ReadingMemoryProjection.sourceBoundary(
            source('epubcfi(/unknown)'), materials),
        isNull);
    expect(
        ReadingMemoryProjection.sourceBoundary(
            source('epubcfi(/6/2)', bookId: 2), materials),
        isNull);
  });
}
