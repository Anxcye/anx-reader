import 'package:anx_reader/models/reading_evidence.dart';
import 'package:anx_reader/service/ai/reading_chunker.dart';
import 'package:anx_reader/service/ai/reading_evidence_resolver.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const resolver = ReadingEvidenceResolver();

  test('returns exact original text and UTF-16 offsets', () {
    const source = '开头😀。检视阅读帮助读者掌握结构。结尾';
    final result = resolver.resolve(
      sourceText: source,
      evidence: '检视阅读帮助读者掌握结构。',
    );

    expect(result?.strategy, ReadingEvidenceMatchStrategy.exact);
    expect(result?.exactText, '检视阅读帮助读者掌握结构。');
    expect(source.substring(result!.startOffset, result.endOffset),
        result.exactText);
  });

  test('normalizes whitespace full-width punctuation and keeps source range',
      () {
    const source = '作者说：“阅读，首先要主动。”\n\n然后再提问。';
    final result = resolver.resolve(
      sourceText: source,
      evidence: '作者说: "阅读, 首先要主动." 然后再提问.',
    );

    expect(result?.strategy, ReadingEvidenceMatchStrategy.normalized);
    expect(result?.exactText, source);
  });

  test('prefers a repeated occurrence inside the current chunk', () {
    const source = '共同证据。前文。共同证据。后文。';
    final chunks = const ReadingChunker().split(
      bookId: 1,
      chapterHref: 'chapter.xhtml',
      chapterTitle: '章节',
      content: source,
      sourceProgress: .1,
      maxCharacters: 256,
    );
    final result = resolver.resolve(
      sourceText: source,
      evidence: '共同证据。',
      preferredStart: source.lastIndexOf('共同证据。'),
      preferredEnd: source.length,
      preferredChunk: null,
    );

    expect(chunks, hasLength(1));
    expect(result?.startOffset, source.lastIndexOf('共同证据。'));
  });

  test('strips citation wrappers but rejects paraphrases and empty evidence',
      () {
    const source = '阅读是一种主动的活动。';
    final wrapped = resolver.resolve(
      sourceText: source,
      evidence: '“……阅读是一种主动的活动。……”',
    );

    expect(wrapped?.strategy, ReadingEvidenceMatchStrategy.sentenceWindow);
    expect(wrapped?.exactText, source);
    expect(resolver.resolve(sourceText: source, evidence: '阅读需要主动参与。'), isNull);
    expect(resolver.resolve(sourceText: source, evidence: '  '), isNull);
  });
}
