part of 'deltas.dart';

/// A thought summary delta update.
class ThoughtSummaryDelta extends InteractionDelta {
  @override
  String get type => 'thought_summary';

  /// The content of the thought summary (text or image).
  final InteractionContent? content;

  /// Creates a [ThoughtSummaryDelta] instance.
  const ThoughtSummaryDelta({this.content});

  /// Creates a [ThoughtSummaryDelta] from JSON.
  factory ThoughtSummaryDelta.fromJson(Map<String, dynamic> json) =>
      ThoughtSummaryDelta(
        content: json['content'] != null
            ? InteractionContent.fromJson(
                json['content'] as Map<String, dynamic>,
              )
            : null,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (content != null) 'content': content!.toJson(),
  };
}
