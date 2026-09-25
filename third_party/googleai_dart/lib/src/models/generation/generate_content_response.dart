import '../content/candidate.dart';
import '../copy_with_sentinel.dart';
import '../metadata/usage_metadata.dart';
import 'prompt_feedback.dart';

/// Response from generating content.
class GenerateContentResponse {
  /// Generated candidates.
  final List<Candidate>? candidates;

  /// Feedback on the prompt.
  final PromptFeedback? promptFeedback;

  /// Token usage metadata.
  final UsageMetadata? usageMetadata;

  /// Model version used for generation.
  final String? modelVersion;

  /// Unique identifier for the response.
  final String? responseId;

  /// Creates a [GenerateContentResponse].
  const GenerateContentResponse({
    this.candidates,
    this.promptFeedback,
    this.usageMetadata,
    this.modelVersion,
    this.responseId,
  });

  /// Creates a [GenerateContentResponse] from JSON.
  factory GenerateContentResponse.fromJson(Map<String, dynamic> json) =>
      GenerateContentResponse(
        candidates: json['candidates'] != null
            ? (json['candidates'] as List)
                  .map((e) => Candidate.fromJson(e as Map<String, dynamic>))
                  .toList()
            : null,
        promptFeedback: json['promptFeedback'] != null
            ? PromptFeedback.fromJson(
                json['promptFeedback'] as Map<String, dynamic>,
              )
            : null,
        usageMetadata: json['usageMetadata'] != null
            ? UsageMetadata.fromJson(
                json['usageMetadata'] as Map<String, dynamic>,
              )
            : null,
        modelVersion: json['modelVersion'] as String?,
        responseId: json['responseId'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (candidates != null)
      'candidates': candidates!.map((e) => e.toJson()).toList(),
    if (promptFeedback != null) 'promptFeedback': promptFeedback!.toJson(),
    if (usageMetadata != null) 'usageMetadata': usageMetadata!.toJson(),
    if (modelVersion != null) 'modelVersion': modelVersion,
    if (responseId != null) 'responseId': responseId,
  };

  /// Creates a copy with replaced values.
  GenerateContentResponse copyWith({
    Object? candidates = unsetCopyWithValue,
    Object? promptFeedback = unsetCopyWithValue,
    Object? usageMetadata = unsetCopyWithValue,
    Object? modelVersion = unsetCopyWithValue,
    Object? responseId = unsetCopyWithValue,
  }) {
    return GenerateContentResponse(
      candidates: candidates == unsetCopyWithValue
          ? this.candidates
          : candidates as List<Candidate>?,
      promptFeedback: promptFeedback == unsetCopyWithValue
          ? this.promptFeedback
          : promptFeedback as PromptFeedback?,
      usageMetadata: usageMetadata == unsetCopyWithValue
          ? this.usageMetadata
          : usageMetadata as UsageMetadata?,
      modelVersion: modelVersion == unsetCopyWithValue
          ? this.modelVersion
          : modelVersion as String?,
      responseId: responseId == unsetCopyWithValue
          ? this.responseId
          : responseId as String?,
    );
  }
}
