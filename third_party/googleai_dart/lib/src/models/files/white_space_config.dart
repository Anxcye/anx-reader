import '../copy_with_sentinel.dart';

/// Configuration for a white space chunking algorithm.
class WhiteSpaceConfig {
  /// Maximum number of tokens per chunk.
  ///
  /// Tokens are defined as words for this chunking algorithm.
  final int? maxTokensPerChunk;

  /// Maximum number of overlapping tokens between two adjacent chunks.
  final int? maxOverlapTokens;

  /// Creates a [WhiteSpaceConfig].
  const WhiteSpaceConfig({this.maxTokensPerChunk, this.maxOverlapTokens});

  /// Creates a [WhiteSpaceConfig] from JSON.
  factory WhiteSpaceConfig.fromJson(Map<String, dynamic> json) =>
      WhiteSpaceConfig(
        maxTokensPerChunk: json['maxTokensPerChunk'] as int?,
        maxOverlapTokens: json['maxOverlapTokens'] as int?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (maxTokensPerChunk != null) 'maxTokensPerChunk': maxTokensPerChunk,
    if (maxOverlapTokens != null) 'maxOverlapTokens': maxOverlapTokens,
  };

  /// Creates a copy with replaced values.
  WhiteSpaceConfig copyWith({
    Object? maxTokensPerChunk = unsetCopyWithValue,
    Object? maxOverlapTokens = unsetCopyWithValue,
  }) {
    return WhiteSpaceConfig(
      maxTokensPerChunk: maxTokensPerChunk == unsetCopyWithValue
          ? this.maxTokensPerChunk
          : maxTokensPerChunk as int?,
      maxOverlapTokens: maxOverlapTokens == unsetCopyWithValue
          ? this.maxOverlapTokens
          : maxOverlapTokens as int?,
    );
  }

  @override
  String toString() =>
      'WhiteSpaceConfig(maxTokensPerChunk: $maxTokensPerChunk, maxOverlapTokens: $maxOverlapTokens)';
}
