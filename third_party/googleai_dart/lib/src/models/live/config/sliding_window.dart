/// Sliding window configuration for context compression.
///
/// Specifies how much context to retain when compression is triggered.
class SlidingWindow {
  /// Target number of tokens to retain after compression.
  final int? targetTokens;

  /// Creates a [SlidingWindow].
  const SlidingWindow({this.targetTokens});

  /// Creates from JSON.
  factory SlidingWindow.fromJson(Map<String, dynamic> json) {
    return SlidingWindow(targetTokens: json['targetTokens'] as int?);
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (targetTokens != null) 'targetTokens': targetTokens,
  };

  /// Creates a copy with the given fields replaced.
  SlidingWindow copyWith({int? targetTokens}) {
    return SlidingWindow(targetTokens: targetTokens ?? this.targetTokens);
  }

  @override
  String toString() => 'SlidingWindow(targetTokens: $targetTokens)';
}
