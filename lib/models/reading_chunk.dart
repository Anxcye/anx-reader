import 'dart:convert';

import 'package:crypto/crypto.dart';

/// A bounded, immutable view over a chapter used by explicit AI tasks.
///
/// Chunks are short-lived task inputs. Their text is never persisted as a new
/// source of truth; [startOffset] and [endOffset] always address the original
/// chapter text.
class ReadingChunk {
  const ReadingChunk({
    required this.id,
    required this.bookId,
    required this.chapterHref,
    required this.chapterTitle,
    required this.index,
    required this.content,
    required this.contentHash,
    required this.chapterContentHash,
    required this.startOffset,
    required this.endOffset,
    required this.sourceProgress,
    required this.pipelineVersion,
  });

  static const currentPipelineVersion = 'reading-chunk.v1';

  final String id;
  final int bookId;
  final String chapterHref;
  final String chapterTitle;
  final int index;
  final String content;
  final String contentHash;
  final String chapterContentHash;
  final int startOffset;
  final int endOffset;
  final double sourceProgress;
  final String pipelineVersion;

  bool containsOffsetRange(int start, int end) =>
      start >= startOffset && end <= endOffset && end >= start;

  /// Metadata suitable for a task checkpoint. Full chapter/chunk text is
  /// intentionally excluded.
  Map<String, dynamic> toCheckpointJson() => {
        'id': id,
        'chapterHref': chapterHref,
        'index': index,
        'contentHash': contentHash,
        'chapterContentHash': chapterContentHash,
        'startOffset': startOffset,
        'endOffset': endOffset,
        'pipelineVersion': pipelineVersion,
      };

  static String digest(String value) =>
      sha256.convert(utf8.encode(value)).toString();
}
