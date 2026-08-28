import 'package:anx_reader/models/reading_chunk.dart';

/// Deterministically splits chapter text for user-triggered AI work.
class ReadingChunker {
  const ReadingChunker();

  List<ReadingChunk> split({
    required int bookId,
    required String chapterHref,
    required String chapterTitle,
    required String content,
    required double sourceProgress,
    int maxCharacters = 6000,
    int overlapCharacters = 0,
    String pipelineVersion = ReadingChunk.currentPipelineVersion,
  }) {
    if (content.trim().isEmpty) return const [];
    if (maxCharacters < 256) {
      throw ArgumentError.value(
          maxCharacters, 'maxCharacters', 'must be >= 256');
    }
    final overlap = overlapCharacters.clamp(0, maxCharacters ~/ 4);
    final chapterHash = ReadingChunk.digest(content);
    final chunks = <ReadingChunk>[];
    var start = 0;
    while (start < content.length) {
      final hardEnd = (start + maxCharacters).clamp(0, content.length);
      var end = hardEnd;
      if (hardEnd < content.length) {
        end = _preferredBoundary(content, start, hardEnd);
      }
      if (end <= start) end = hardEnd;
      final text = content.substring(start, end);
      final contentHash = ReadingChunk.digest(text);
      final index = chunks.length;
      final identity = [
        bookId,
        chapterHref.split('#').first,
        chapterHash,
        pipelineVersion,
        index,
        start,
        end,
      ].join('|');
      chunks.add(ReadingChunk(
        id: 'reading-chunk-${ReadingChunk.digest(identity)}',
        bookId: bookId,
        chapterHref: chapterHref,
        chapterTitle: chapterTitle,
        index: index,
        content: text,
        contentHash: contentHash,
        chapterContentHash: chapterHash,
        startOffset: start,
        endOffset: end,
        sourceProgress: sourceProgress,
        pipelineVersion: pipelineVersion,
      ));
      if (end == content.length) break;
      final next = end - overlap;
      start = next > start ? next : end;
    }
    return chunks;
  }

  int _preferredBoundary(String text, int start, int hardEnd) {
    // Avoid tiny chunks: only consider natural boundaries in the latter 40%.
    final searchStart = start + ((hardEnd - start) * .6).floor();
    final paragraph = text.lastIndexOf(RegExp(r'\n\s*\n'), hardEnd - 1);
    if (paragraph >= searchStart) {
      final match = RegExp(r'\n\s*\n').matchAsPrefix(text, paragraph);
      return match?.end ?? paragraph + 1;
    }
    final sentence = text.lastIndexOf(
      RegExp(r'''[。！？!?；;\.](?:[”’"'])?'''),
      hardEnd - 1,
    );
    if (sentence >= searchStart) {
      final match =
          RegExp(r'''[。！？!?；;\.](?:[”’"'])?''').matchAsPrefix(text, sentence);
      return match?.end ?? sentence + 1;
    }
    final newline = text.lastIndexOf('\n', hardEnd - 1);
    if (newline >= searchStart) return newline + 1;
    return hardEnd;
  }
}

const readingChunker = ReadingChunker();
