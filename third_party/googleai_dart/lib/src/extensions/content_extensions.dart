import '../models/content/content.dart';
import '../models/content/part.dart';
import '../models/tools/function_call.dart';

/// Convenience extensions for [Content].
extension ContentExtensions on Content {
  /// Concatenated text from all text parts.
  ///
  /// Returns null if no text parts exist.
  String? get text {
    final buffer = StringBuffer();
    var hasText = false;
    for (final part in parts) {
      if (part is TextPart) {
        buffer.write(part.text);
        hasText = true;
      }
    }
    return hasText ? buffer.toString() : null;
  }

  /// All function calls in this content.
  List<FunctionCall> get functionCalls => [
    for (final part in parts)
      if (part is FunctionCallPart) part.functionCall,
  ];

  /// All text parts.
  List<TextPart> get textParts => parts.whereType<TextPart>().toList();

  /// All inline data parts.
  List<InlineDataPart> get inlineDataParts =>
      parts.whereType<InlineDataPart>().toList();

  /// All file data parts.
  List<FileDataPart> get fileDataParts =>
      parts.whereType<FileDataPart>().toList();

  /// All function call parts.
  List<FunctionCallPart> get functionCallParts =>
      parts.whereType<FunctionCallPart>().toList();

  /// All function response parts.
  List<FunctionResponsePart> get functionResponseParts =>
      parts.whereType<FunctionResponsePart>().toList();

  /// All executable code parts.
  List<ExecutableCodePart> get executableCodeParts =>
      parts.whereType<ExecutableCodePart>().toList();

  /// All code execution result parts.
  List<CodeExecutionResultPart> get codeExecutionResultParts =>
      parts.whereType<CodeExecutionResultPart>().toList();
}
