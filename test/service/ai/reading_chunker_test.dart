import 'package:anx_reader/service/ai/reading_chunker.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const chunker = ReadingChunker();
  String repeat(String value, int count) => List.filled(count, value).join();

  test('short chapter produces one stable offset-addressed chunk', () {
    const content = '第一段。\n\n第二段。';
    final first = chunker.split(
      bookId: 1,
      chapterHref: 'chapter-1.xhtml',
      chapterTitle: '第一章',
      content: content,
      sourceProgress: .1,
      maxCharacters: 256,
    );
    final second = chunker.split(
      bookId: 1,
      chapterHref: 'chapter-1.xhtml',
      chapterTitle: '第一章',
      content: content,
      sourceProgress: .1,
      maxCharacters: 256,
    );

    expect(first, hasLength(1));
    expect(first.single.content, content);
    expect(first.single.startOffset, 0);
    expect(first.single.endOffset, content.length);
    expect(first.single.id, second.single.id);
    expect(first.single.toCheckpointJson(), isNot(contains('content')));
  });

  test('prefers paragraph and sentence boundaries without losing text', () {
    final content =
        '${repeat('甲', 170)}\n\n${repeat('乙', 130)}。${repeat('丙', 170)}';
    final chunks = chunker.split(
      bookId: 2,
      chapterHref: 'long.xhtml',
      chapterTitle: '长章',
      content: content,
      sourceProgress: .2,
      maxCharacters: 256,
    );

    expect(chunks.length, greaterThan(1));
    expect(chunks.first.content, endsWith('\n\n'));
    expect(chunks.every((item) => item.content.length <= 256), isTrue);
    expect(chunks.map((item) => item.content).join(), content);
    for (final chunk in chunks) {
      expect(
          content.substring(chunk.startOffset, chunk.endOffset), chunk.content);
    }
  });

  test('hard splits text without natural boundaries and content changes id',
      () {
    final chunks = chunker.split(
      bookId: 3,
      chapterHref: 'hard.xhtml',
      chapterTitle: '无标点',
      content: repeat('字', 600),
      sourceProgress: .3,
      maxCharacters: 256,
    );
    final changed = chunker.split(
      bookId: 3,
      chapterHref: 'hard.xhtml',
      chapterTitle: '无标点',
      content: '${repeat('字', 599)}词',
      sourceProgress: .3,
      maxCharacters: 256,
    );

    expect(chunks, hasLength(3));
    expect(chunks.map((item) => item.content).join(), repeat('字', 600));
    expect(chunks.first.id, isNot(changed.first.id));
  });

  test('optional overlap preserves original offsets', () {
    final content = List.generate(600, (index) => '${index % 10}').join();
    final chunks = chunker.split(
      bookId: 4,
      chapterHref: 'overlap.xhtml',
      chapterTitle: '重叠',
      content: content,
      sourceProgress: .4,
      maxCharacters: 256,
      overlapCharacters: 20,
    );

    expect(chunks[1].startOffset, chunks[0].endOffset - 20);
    for (final chunk in chunks) {
      expect(
          content.substring(chunk.startOffset, chunk.endOffset), chunk.content);
    }
  });
}
