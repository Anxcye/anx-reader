import 'grounding_passage.dart';

/// A repeated list of passages.
class GroundingPassages {
  /// List of passages.
  final List<GroundingPassage>? passages;

  /// Creates a [GroundingPassages].
  const GroundingPassages({this.passages});

  /// Creates a [GroundingPassages] from JSON.
  factory GroundingPassages.fromJson(Map<String, dynamic> json) =>
      GroundingPassages(
        passages: json['passages'] != null
            ? (json['passages'] as List)
                  .map(
                    (e) => GroundingPassage.fromJson(e as Map<String, dynamic>),
                  )
                  .toList()
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (passages != null) 'passages': passages!.map((e) => e.toJson()).toList(),
  };
}
