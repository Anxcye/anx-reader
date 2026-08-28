import 'dart:convert';
import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/service/ai/book_wiki_generation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('generation scope and supported kinds use stable ids', () {
    expect(BookWikiGenerationScope.readBoundary.id, 'read_boundary');
    expect(BookWikiGenerationScope.fullBook.id, 'full_book');
    expect(BookWikiEntryKinds.supported,
        containsAll(['wiki.concept', 'wiki.method', 'wiki.character']));
  });

  test('Wiki generation accepts fenced and prefaced JSON responses', () {
    final service = BookWikiGenerationService();
    const payload =
        '[{"kind":"wiki.concept","title":"检视阅读","summary":"快速掌握全书结构"}]';

    expect(service.decodeResponse('```json\n$payload\n```')?.single['title'],
        '检视阅读');
    expect(service.decodeResponse('以下是整理结果：\n$payload')?.single['kind'],
        'wiki.concept');
  });

  test('Wiki generation excludes front matter that is not core book content',
      () {
    expect(BookWikiGenerationService.isEligibleChapterTitle('译 序'), isFalse);
    expect(BookWikiGenerationService.isEligibleChapterTitle('作者简介'), isFalse);
    expect(BookWikiGenerationService.isEligibleChapterTitle('作品简介'), isFalse);
    expect(BookWikiGenerationService.isEligibleChapterTitle('第一章 阅读的活力与艺术'),
        isTrue);
  });

  test('Wiki entry database roundtrip keeps spoiler boundary and correction',
      () {
    final entry = BookWikiEntry(
        id: 'reading-levels',
        bookId: 1,
        kind: BookWikiEntryKinds.concept,
        title: '四种阅读层次',
        visibleFromProgress: .2,
        userCorrected: true,
        sourceArtifactIds: const ['content:hash'],
        createdAt: 1,
        updatedAt: 2);
    final restored =
        BookWikiEntry.fromDb(Map<String, dynamic>.from(entry.toDb()));
    expect(restored.visibleFromProgress, .2);
    expect(restored.userCorrected, isTrue);
    expect(jsonDecode(restored.toDb()['source_artifact_ids_json']! as String),
        ['content:hash']);
  });
}
