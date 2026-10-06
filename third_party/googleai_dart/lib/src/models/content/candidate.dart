import '../copy_with_sentinel.dart';
import '../metadata/finish_reason.dart';
import '../metadata/grounding_metadata.dart';
import '../safety/safety_rating.dart';
import 'citation_metadata.dart';
import 'content.dart';
import 'logprobs_result.dart';

/// A generated response from the model.
class Candidate {
  /// Generated content.
  final Content? content;

  /// Why generation stopped.
  final FinishReason? finishReason;

  /// Human-readable message describing the finish reason.
  final String? finishMessage;

  /// Safety assessment.
  final List<SafetyRating>? safetyRatings;

  /// Source citations.
  final CitationMetadata? citationMetadata;

  /// Tokens in this candidate.
  final int? tokenCount;

  /// Candidate index (0-based).
  final int? index;

  /// Average log probability.
  final double? avgLogprobs;

  /// Token-level logprobs.
  final LogprobsResult? logprobsResult;

  /// Grounding metadata for this candidate.
  final GroundingMetadata? groundingMetadata;

  /// Attribution information for sources that contributed to a grounded answer.
  ///
  /// This field is populated for `GenerateAnswer` calls.
  final List<Map<String, dynamic>>? groundingAttributions;

  /// Metadata related to URL context retrieval tool.
  final Map<String, dynamic>? urlContextMetadata;

  /// Creates a [Candidate].
  const Candidate({
    this.content,
    this.finishReason,
    this.finishMessage,
    this.safetyRatings,
    this.citationMetadata,
    this.tokenCount,
    this.index,
    this.avgLogprobs,
    this.logprobsResult,
    this.groundingMetadata,
    this.groundingAttributions,
    this.urlContextMetadata,
  });

  /// Creates a [Candidate] from JSON.
  factory Candidate.fromJson(Map<String, dynamic> json) => Candidate(
    content: json['content'] != null
        ? Content.fromJson(json['content'] as Map<String, dynamic>)
        : null,
    finishReason: json['finishReason'] != null
        ? finishReasonFromString(json['finishReason'] as String?)
        : null,
    finishMessage: json['finishMessage'] as String?,
    safetyRatings: json['safetyRatings'] != null
        ? (json['safetyRatings'] as List)
              .map((e) => SafetyRating.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
    citationMetadata: json['citationMetadata'] != null
        ? CitationMetadata.fromJson(
            json['citationMetadata'] as Map<String, dynamic>,
          )
        : null,
    tokenCount: json['tokenCount'] as int?,
    index: json['index'] as int?,
    avgLogprobs: (json['avgLogprobs'] as num?)?.toDouble(),
    logprobsResult: json['logprobsResult'] != null
        ? LogprobsResult.fromJson(
            json['logprobsResult'] as Map<String, dynamic>,
          )
        : null,
    groundingMetadata: json['groundingMetadata'] != null
        ? GroundingMetadata.fromJson(
            json['groundingMetadata'] as Map<String, dynamic>,
          )
        : null,
    groundingAttributions: (json['groundingAttributions'] as List<dynamic>?)
        ?.map((e) => e as Map<String, dynamic>)
        .toList(),
    urlContextMetadata: json['urlContextMetadata'] as Map<String, dynamic>?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (content != null) 'content': content!.toJson(),
    if (finishReason != null)
      'finishReason': finishReasonToString(finishReason!),
    if (finishMessage != null) 'finishMessage': finishMessage,
    if (safetyRatings != null)
      'safetyRatings': safetyRatings!.map((e) => e.toJson()).toList(),
    if (citationMetadata != null)
      'citationMetadata': citationMetadata!.toJson(),
    if (tokenCount != null) 'tokenCount': tokenCount,
    if (index != null) 'index': index,
    if (avgLogprobs != null) 'avgLogprobs': avgLogprobs,
    if (logprobsResult != null) 'logprobsResult': logprobsResult!.toJson(),
    if (groundingMetadata != null)
      'groundingMetadata': groundingMetadata!.toJson(),
    if (groundingAttributions != null)
      'groundingAttributions': groundingAttributions,
    if (urlContextMetadata != null) 'urlContextMetadata': urlContextMetadata,
  };

  /// Creates a copy with replaced values.
  Candidate copyWith({
    Object? content = unsetCopyWithValue,
    Object? finishReason = unsetCopyWithValue,
    Object? finishMessage = unsetCopyWithValue,
    Object? safetyRatings = unsetCopyWithValue,
    Object? citationMetadata = unsetCopyWithValue,
    Object? tokenCount = unsetCopyWithValue,
    Object? index = unsetCopyWithValue,
    Object? avgLogprobs = unsetCopyWithValue,
    Object? logprobsResult = unsetCopyWithValue,
    Object? groundingMetadata = unsetCopyWithValue,
    Object? groundingAttributions = unsetCopyWithValue,
    Object? urlContextMetadata = unsetCopyWithValue,
  }) {
    return Candidate(
      content: content == unsetCopyWithValue
          ? this.content
          : content as Content?,
      finishReason: finishReason == unsetCopyWithValue
          ? this.finishReason
          : finishReason as FinishReason?,
      finishMessage: finishMessage == unsetCopyWithValue
          ? this.finishMessage
          : finishMessage as String?,
      safetyRatings: safetyRatings == unsetCopyWithValue
          ? this.safetyRatings
          : safetyRatings as List<SafetyRating>?,
      citationMetadata: citationMetadata == unsetCopyWithValue
          ? this.citationMetadata
          : citationMetadata as CitationMetadata?,
      tokenCount: tokenCount == unsetCopyWithValue
          ? this.tokenCount
          : tokenCount as int?,
      index: index == unsetCopyWithValue ? this.index : index as int?,
      avgLogprobs: avgLogprobs == unsetCopyWithValue
          ? this.avgLogprobs
          : avgLogprobs as double?,
      logprobsResult: logprobsResult == unsetCopyWithValue
          ? this.logprobsResult
          : logprobsResult as LogprobsResult?,
      groundingMetadata: groundingMetadata == unsetCopyWithValue
          ? this.groundingMetadata
          : groundingMetadata as GroundingMetadata?,
      groundingAttributions: groundingAttributions == unsetCopyWithValue
          ? this.groundingAttributions
          : groundingAttributions as List<Map<String, dynamic>>?,
      urlContextMetadata: urlContextMetadata == unsetCopyWithValue
          ? this.urlContextMetadata
          : urlContextMetadata as Map<String, dynamic>?,
    );
  }
}
