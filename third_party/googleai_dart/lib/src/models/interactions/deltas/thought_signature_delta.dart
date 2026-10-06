part of 'deltas.dart';

/// A thought signature delta update.
class ThoughtSignatureDelta extends InteractionDelta {
  @override
  String get type => 'thought_signature';

  /// Signature to match the backend source to be part of the generation.
  final String? signature;

  /// Creates a [ThoughtSignatureDelta] instance.
  const ThoughtSignatureDelta({this.signature});

  /// Creates a [ThoughtSignatureDelta] from JSON.
  factory ThoughtSignatureDelta.fromJson(Map<String, dynamic> json) =>
      ThoughtSignatureDelta(signature: json['signature'] as String?);

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (signature != null) 'signature': signature,
  };
}
