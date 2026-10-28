import '../models/content/candidate.dart';
import '../models/content/part.dart';
import '../models/generation/generate_content_response.dart';
import '../models/tools/function_call.dart';
import 'candidate_extensions.dart';

/// Convenience extensions for [GenerateContentResponse].
extension GenerateContentResponseExtensions on GenerateContentResponse {
  /// Returns the first candidate, or null if none exist.
  Candidate? get firstCandidate => candidates?.firstOrNull;

  /// Concatenated text from all text parts across all candidates.
  ///
  /// Returns null if no text parts exist.
  ///
  /// Example:
  /// ```dart
  /// final response = await client.models.generateContent(...);
  /// print(response.text); // Prints the generated text
  /// ```
  String? get text {
    final buffer = StringBuffer();
    var hasText = false;
    for (final candidate in candidates ?? <Candidate>[]) {
      final candidateText = candidate.text;
      if (candidateText != null) {
        buffer.write(candidateText);
        hasText = true;
      }
    }
    return hasText ? buffer.toString() : null;
  }

  /// All function calls from all candidates.
  ///
  /// Example:
  /// ```dart
  /// for (final call in response.functionCalls) {
  ///   print('Function: ${call.name}, Args: ${call.args}');
  /// }
  /// ```
  List<FunctionCall> get functionCalls {
    return [
      for (final candidate in candidates ?? <Candidate>[])
        ...candidate.functionCalls,
    ];
  }

  /// Executable code from the first candidate (for code execution tool).
  ///
  /// Returns null if no executable code exists.
  String? get executableCode {
    for (final part in firstCandidate?.parts ?? <Part>[]) {
      if (part is ExecutableCodePart) {
        return part.executableCode.code;
      }
    }
    return null;
  }

  /// Code execution result output from the first candidate.
  ///
  /// Returns null if no code execution result exists.
  String? get codeExecutionResult {
    for (final part in firstCandidate?.parts ?? <Part>[]) {
      if (part is CodeExecutionResultPart) {
        return part.codeExecutionResult.output;
      }
    }
    return null;
  }

  /// Inline data (base64) from the first candidate.
  ///
  /// Useful for image generation responses.
  /// Returns null if no inline data exists.
  String? get data {
    for (final part in firstCandidate?.parts ?? <Part>[]) {
      if (part is InlineDataPart) {
        return part.inlineData.data;
      }
    }
    return null;
  }

  /// True if the response has valid content.
  bool get hasContent =>
      candidates?.any((c) => c.content?.parts.isNotEmpty ?? false) ?? false;

  /// All parts from all candidates.
  List<Part> get allParts => [
    for (final candidate in candidates ?? <Candidate>[]) ...candidate.parts,
  ];
}
