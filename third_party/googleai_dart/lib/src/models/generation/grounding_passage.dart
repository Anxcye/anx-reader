import '../content/content.dart';

/// Passage included inline with a grounding configuration.
class GroundingPassage {
  /// Identifier for the passage for attributing this passage in grounded
  /// answers.
  final String? id;

  /// Content of the passage.
  final Content? content;

  /// Creates a [GroundingPassage].
  const GroundingPassage({this.id, this.content});

  /// Creates a [GroundingPassage] from JSON.
  factory GroundingPassage.fromJson(Map<String, dynamic> json) =>
      GroundingPassage(
        id: json['id'] as String?,
        content: json['content'] != null
            ? Content.fromJson(json['content'] as Map<String, dynamic>)
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    if (content != null) 'content': content!.toJson(),
  };
}
