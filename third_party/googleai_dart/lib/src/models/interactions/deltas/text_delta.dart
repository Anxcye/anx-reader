part of 'deltas.dart';

/// A text delta update.
class TextDelta extends InteractionDelta {
  @override
  String get type => 'text';

  /// The text content.
  final String? text;

  /// Citation information for model-generated content.
  final List<Annotation>? annotations;

  /// Creates a [TextDelta] instance.
  const TextDelta({this.text, this.annotations});

  /// Creates a [TextDelta] from JSON.
  factory TextDelta.fromJson(Map<String, dynamic> json) => TextDelta(
    text: json['text'] as String?,
    annotations: (json['annotations'] as List<dynamic>?)
        ?.map((e) => Annotation.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (text != null) 'text': text,
    if (annotations != null)
      'annotations': annotations!.map((e) => e.toJson()).toList(),
  };
}
