import '../models/content/candidate.dart';
import '../models/content/part.dart';
import '../models/tools/function_call.dart';
import 'content_extensions.dart';

/// Convenience extensions for [Candidate].
extension CandidateExtensions on Candidate {
  /// Concatenated text from all text parts in this candidate's content.
  ///
  /// Returns null if no text parts exist.
  String? get text => content?.text;

  /// All function calls from this candidate's content.
  List<FunctionCall> get functionCalls => content?.functionCalls ?? [];

  /// All parts from this candidate's content.
  List<Part> get parts => content?.parts ?? [];

  /// True if this candidate has text content.
  bool get hasText => parts.any((p) => p is TextPart);

  /// True if this candidate has function calls.
  bool get hasFunctionCalls => parts.any((p) => p is FunctionCallPart);
}
