import '../copy_with_sentinel.dart';
import '../metadata/modality_token_count.dart';

/// Response from counting tokens.
class CountTokensResponse {
  /// Total number of tokens.
  final int totalTokens;

  /// Number of tokens in the cached part of the prompt (the cached content).
  final int? cachedContentTokenCount;

  /// List of modalities that were processed in the request input.
  final List<ModalityTokenCount>? promptTokensDetails;

  /// List of modalities that were processed in the cached content.
  final List<ModalityTokenCount>? cacheTokensDetails;

  /// Creates a [CountTokensResponse].
  const CountTokensResponse({
    required this.totalTokens,
    this.cachedContentTokenCount,
    this.promptTokensDetails,
    this.cacheTokensDetails,
  });

  /// Creates a [CountTokensResponse] from JSON.
  factory CountTokensResponse.fromJson(Map<String, dynamic> json) =>
      CountTokensResponse(
        totalTokens: json['totalTokens'] as int,
        cachedContentTokenCount: json['cachedContentTokenCount'] as int?,
        promptTokensDetails: json['promptTokensDetails'] != null
            ? (json['promptTokensDetails'] as List)
                  .map(
                    (e) =>
                        ModalityTokenCount.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
            : null,
        cacheTokensDetails: json['cacheTokensDetails'] != null
            ? (json['cacheTokensDetails'] as List)
                  .map(
                    (e) =>
                        ModalityTokenCount.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'totalTokens': totalTokens,
    if (cachedContentTokenCount != null)
      'cachedContentTokenCount': cachedContentTokenCount,
    if (promptTokensDetails != null)
      'promptTokensDetails': promptTokensDetails!
          .map((e) => e.toJson())
          .toList(),
    if (cacheTokensDetails != null)
      'cacheTokensDetails': cacheTokensDetails!.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  CountTokensResponse copyWith({
    Object? totalTokens = unsetCopyWithValue,
    Object? cachedContentTokenCount = unsetCopyWithValue,
    Object? promptTokensDetails = unsetCopyWithValue,
    Object? cacheTokensDetails = unsetCopyWithValue,
  }) {
    return CountTokensResponse(
      totalTokens: totalTokens == unsetCopyWithValue
          ? this.totalTokens
          : totalTokens! as int,
      cachedContentTokenCount: cachedContentTokenCount == unsetCopyWithValue
          ? this.cachedContentTokenCount
          : cachedContentTokenCount as int?,
      promptTokensDetails: promptTokensDetails == unsetCopyWithValue
          ? this.promptTokensDetails
          : promptTokensDetails as List<ModalityTokenCount>?,
      cacheTokensDetails: cacheTokensDetails == unsetCopyWithValue
          ? this.cacheTokensDetails
          : cacheTokensDetails as List<ModalityTokenCount>?,
    );
  }
}
