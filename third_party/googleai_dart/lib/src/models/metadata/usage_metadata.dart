import '../copy_with_sentinel.dart';

/// Token usage metadata for the request/response.
class UsageMetadata {
  /// Number of tokens in the prompt.
  final int? promptTokenCount;

  /// Number of tokens in the response(s).
  final int? candidatesTokenCount;

  /// Total token count.
  final int? totalTokenCount;

  /// Number of cached tokens in the prompt.
  final int? cachedContentTokenCount;

  /// Creates a [UsageMetadata].
  const UsageMetadata({
    this.promptTokenCount,
    this.candidatesTokenCount,
    this.totalTokenCount,
    this.cachedContentTokenCount,
  });

  /// Creates a [UsageMetadata] from JSON.
  factory UsageMetadata.fromJson(Map<String, dynamic> json) => UsageMetadata(
    promptTokenCount: json['promptTokenCount'] as int?,
    candidatesTokenCount: json['candidatesTokenCount'] as int?,
    totalTokenCount: json['totalTokenCount'] as int?,
    cachedContentTokenCount: json['cachedContentTokenCount'] as int?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (promptTokenCount != null) 'promptTokenCount': promptTokenCount,
    if (candidatesTokenCount != null)
      'candidatesTokenCount': candidatesTokenCount,
    if (totalTokenCount != null) 'totalTokenCount': totalTokenCount,
    if (cachedContentTokenCount != null)
      'cachedContentTokenCount': cachedContentTokenCount,
  };

  /// Creates a copy with replaced values.
  UsageMetadata copyWith({
    Object? promptTokenCount = unsetCopyWithValue,
    Object? candidatesTokenCount = unsetCopyWithValue,
    Object? totalTokenCount = unsetCopyWithValue,
    Object? cachedContentTokenCount = unsetCopyWithValue,
  }) {
    return UsageMetadata(
      promptTokenCount: promptTokenCount == unsetCopyWithValue
          ? this.promptTokenCount
          : promptTokenCount as int?,
      candidatesTokenCount: candidatesTokenCount == unsetCopyWithValue
          ? this.candidatesTokenCount
          : candidatesTokenCount as int?,
      totalTokenCount: totalTokenCount == unsetCopyWithValue
          ? this.totalTokenCount
          : totalTokenCount as int?,
      cachedContentTokenCount: cachedContentTokenCount == unsetCopyWithValue
          ? this.cachedContentTokenCount
          : cachedContentTokenCount as int?,
    );
  }
}
