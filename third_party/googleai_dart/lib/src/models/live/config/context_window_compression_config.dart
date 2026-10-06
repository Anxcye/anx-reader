import 'sliding_window.dart';

/// Configuration for context window compression.
///
/// When the context window grows too large, compression can be triggered
/// to reduce it to a target size while preserving important context.
class ContextWindowCompressionConfig {
  /// Token count that triggers compression.
  ///
  /// When the context exceeds this number of tokens, compression is applied.
  final int? triggerTokens;

  /// Sliding window configuration for compression.
  final SlidingWindow? slidingWindow;

  /// Creates a [ContextWindowCompressionConfig].
  const ContextWindowCompressionConfig({
    this.triggerTokens,
    this.slidingWindow,
  });

  /// Creates from JSON.
  factory ContextWindowCompressionConfig.fromJson(Map<String, dynamic> json) {
    return ContextWindowCompressionConfig(
      triggerTokens: json['triggerTokens'] as int?,
      slidingWindow: json['slidingWindow'] != null
          ? SlidingWindow.fromJson(
              json['slidingWindow'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (triggerTokens != null) 'triggerTokens': triggerTokens,
    if (slidingWindow != null) 'slidingWindow': slidingWindow!.toJson(),
  };

  /// Creates a copy with the given fields replaced.
  ContextWindowCompressionConfig copyWith({
    int? triggerTokens,
    SlidingWindow? slidingWindow,
  }) {
    return ContextWindowCompressionConfig(
      triggerTokens: triggerTokens ?? this.triggerTokens,
      slidingWindow: slidingWindow ?? this.slidingWindow,
    );
  }

  @override
  String toString() =>
      'ContextWindowCompressionConfig(triggerTokens: $triggerTokens, '
      'slidingWindow: $slidingWindow)';
}
