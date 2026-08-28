import 'package:anx_reader/models/reading_chunk.dart';
import 'package:anx_reader/models/reading_evidence.dart';

class _NormalizedText {
  const _NormalizedText(this.text, this.starts, this.ends);
  final String text;
  final List<int> starts;
  final List<int> ends;
}

/// Resolves model-provided evidence back to an exact original text range.
/// No fuzzy or model-assisted matching is performed.
class ReadingEvidenceResolver {
  const ReadingEvidenceResolver();

  ReadingEvidenceResolution? resolve({
    required String sourceText,
    required String evidence,
    ReadingChunk? preferredChunk,
    int? preferredStart,
    int? preferredEnd,
  }) {
    var query = evidence.trim();
    if (query.isEmpty || sourceText.isEmpty) return null;
    final rangeStart = (preferredChunk?.startOffset ?? preferredStart ?? 0)
        .clamp(0, sourceText.length);
    final rangeEnd =
        (preferredChunk?.endOffset ?? preferredEnd ?? sourceText.length)
            .clamp(rangeStart, sourceText.length);

    final exact = _chooseOccurrence(sourceText, query, rangeStart, rangeEnd);
    if (exact != null) {
      return _resolution(sourceText, exact, exact + query.length,
          ReadingEvidenceMatchStrategy.exact, 1);
    }

    final normalized = _resolveNormalized(
      sourceText: sourceText,
      query: query,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      strategy: ReadingEvidenceMatchStrategy.normalized,
      confidence: .96,
    );
    if (normalized != null) return normalized;

    // Models often wrap quotations in ellipses or quotation marks. Removing
    // only wrappers remains deterministic; paraphrased evidence is rejected.
    query = _stripCitationWrappers(query);
    if (query.isEmpty || query == evidence.trim()) return null;
    return _resolveNormalized(
      sourceText: sourceText,
      query: query,
      rangeStart: rangeStart,
      rangeEnd: rangeEnd,
      strategy: ReadingEvidenceMatchStrategy.sentenceWindow,
      confidence: .9,
    );
  }

  ReadingEvidenceResolution? _resolveNormalized({
    required String sourceText,
    required String query,
    required int rangeStart,
    required int rangeEnd,
    required ReadingEvidenceMatchStrategy strategy,
    required double confidence,
  }) {
    final source = _normalize(sourceText);
    final needle = _normalize(query).text;
    if (needle.isEmpty || source.text.isEmpty) return null;
    final occurrences = <int>[];
    var from = 0;
    while (true) {
      final index = source.text.indexOf(needle, from);
      if (index < 0) break;
      occurrences.add(index);
      from = index + 1;
    }
    if (occurrences.isEmpty) return null;
    final index = occurrences.firstWhere(
      (item) {
        final start = source.starts[item];
        final end = source.ends[item + needle.length - 1];
        return start >= rangeStart && end <= rangeEnd;
      },
      orElse: () => -1,
    );
    if (index < 0) return null;
    final start = source.starts[index];
    final end = source.ends[index + needle.length - 1];
    return _resolution(sourceText, start, end, strategy, confidence);
  }

  int? _chooseOccurrence(
      String source, String query, int preferredStart, int preferredEnd) {
    var first = -1;
    var from = 0;
    while (true) {
      final index = source.indexOf(query, from);
      if (index < 0) break;
      first = first < 0 ? index : first;
      if (index >= preferredStart && index + query.length <= preferredEnd) {
        return index;
      }
      from = index + 1;
    }
    if (first < 0) return null;
    // A preferred chunk is a safety boundary, not merely a tie breaker.
    if (preferredStart > 0 || preferredEnd < source.length) return null;
    return first;
  }

  ReadingEvidenceResolution _resolution(String source, int start, int end,
          ReadingEvidenceMatchStrategy strategy, double confidence) =>
      ReadingEvidenceResolution(
        exactText: source.substring(start, end),
        startOffset: start,
        endOffset: end,
        strategy: strategy,
        confidence: confidence,
      );

  _NormalizedText _normalize(String input) {
    final output = StringBuffer();
    final starts = <int>[];
    final ends = <int>[];
    for (var i = 0; i < input.length;) {
      // Dart string offsets are UTF-16. Read a single rune without losing the
      // offset mapping for supplementary characters.
      final code = input.codeUnitAt(i);
      final width = code >= 0xD800 && code <= 0xDBFF ? 2 : 1;
      final actualRune =
          String.fromCharCodes(input.codeUnits.sublist(i, i + width))
              .runes
              .first;
      if (_isWhitespace(actualRune)) {
        i += width;
        continue;
      }
      final normalized = _normalizeRune(actualRune);
      output.write(normalized);
      for (var j = 0; j < normalized.length; j++) {
        starts.add(i);
        ends.add(i + width);
      }
      i += width;
    }
    return _NormalizedText(output.toString(), starts, ends);
  }

  bool _isWhitespace(int rune) =>
      rune == 0x20 || rune == 0xA0 || String.fromCharCode(rune).trim().isEmpty;

  String _normalizeRune(int rune) {
    if (rune >= 0xFF01 && rune <= 0xFF5E) {
      return String.fromCharCode(rune - 0xFEE0).toLowerCase();
    }
    return switch (rune) {
      0x3002 => '.',
      0xFF0C => ',',
      0x3001 => ',',
      0xFF1A => ':',
      0xFF1B => ';',
      0xFF01 => '!',
      0xFF1F => '?',
      0x201C || 0x201D || 0x300C || 0x300D => '"',
      0x2018 || 0x2019 => "'",
      _ => String.fromCharCode(rune).toLowerCase(),
    };
  }

  String _stripCitationWrappers(String value) => value
      .replaceFirst(RegExp(r'''^[\s…\.\u2026「『“”"']+'''), '')
      .replaceFirst(RegExp(r'''[\s…\.\u2026」』“”"']+$'''), '')
      .trim();
}

const readingEvidenceResolver = ReadingEvidenceResolver();
