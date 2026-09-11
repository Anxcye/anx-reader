import '../copy_with_sentinel.dart';

/// Usage metadata for cached content.
class CachedContentUsageMetadata {
  /// Total number of tokens in the cached content.
  final int? totalTokenCount;

  /// Creates a [CachedContentUsageMetadata].
  const CachedContentUsageMetadata({this.totalTokenCount});

  /// Creates a [CachedContentUsageMetadata] from JSON.
  factory CachedContentUsageMetadata.fromJson(Map<String, dynamic> json) =>
      CachedContentUsageMetadata(
        totalTokenCount: json['totalTokenCount'] as int?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (totalTokenCount != null) 'totalTokenCount': totalTokenCount,
  };

  /// Creates a copy with replaced values.
  CachedContentUsageMetadata copyWith({
    Object? totalTokenCount = unsetCopyWithValue,
  }) {
    return CachedContentUsageMetadata(
      totalTokenCount: totalTokenCount == unsetCopyWithValue
          ? this.totalTokenCount
          : totalTokenCount as int?,
    );
  }
}
