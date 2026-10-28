import 'dart:async';
import 'dart:convert';

/// Parses an SSE (Server-Sent Events) stream into a stream of JSON objects.
///
/// Implements parsing according to the WHATWG SSE specification:
/// https://html.spec.whatwg.org/multipage/server-sent-events.html
///
/// SSE Format: Each line can be one of:
/// - `data: value` (standard format with space after colon)
/// - `data:value` (format without space, used by some providers)
/// - `data:[DONE]` (termination signal, filtered out)
///
/// Per the WHATWG spec, the space after the colon is optional. When present,
/// exactly one leading space should be removed from the value. We use `.trim()`
/// to handle both formats and any additional whitespace variations robustly.
///
/// This parser:
/// 1. Filters for lines starting with 'data:' (excluding '[DONE]' markers)
/// 2. Extracts the value after 'data:' and trims whitespace
/// 3. Parses the value as JSON and yields the resulting map
/// 4. Gracefully skips malformed JSON lines
Stream<Map<String, dynamic>> parseSSE(Stream<String> stream) async* {
  await for (final line in stream) {
    if (line.startsWith('data:')) {
      final data = line.substring(5).trim();
      if (data.isNotEmpty && data != '[DONE]') {
        try {
          yield jsonDecode(data) as Map<String, dynamic>;
        } catch (_) {
          // Skip malformed JSON
        }
      }
    }
  }
}

/// Parses an NDJSON stream into a stream of JSON objects.
Stream<Map<String, dynamic>> parseNDJSON(Stream<String> stream) async* {
  await for (final line in stream) {
    final trimmed = line.trim();
    if (trimmed.isNotEmpty) {
      try {
        yield jsonDecode(trimmed) as Map<String, dynamic>;
      } catch (_) {
        // Skip malformed JSON
      }
    }
  }
}

/// Converts a byte stream to a line stream.
Stream<String> bytesToLines(Stream<List<int>> byteStream) {
  return byteStream
      .cast<List<int>>()
      .transform(utf8.decoder)
      .transform(const LineSplitter());
}
