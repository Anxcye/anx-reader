part of 'content.dart';

/// A text content block.
class TextContent extends InteractionContent {
  @override
  String get type => 'text';

  /// The text content.
  final String? text;

  /// Citation information for model-generated content.
  final List<Annotation>? annotations;

  /// Creates a [TextContent] instance.
  const TextContent({this.text, this.annotations});

  /// Creates a [TextContent] from JSON.
  factory TextContent.fromJson(Map<String, dynamic> json) => TextContent(
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

  /// Creates a copy with replaced values.
  TextContent copyWith({
    Object? text = unsetCopyWithValue,
    Object? annotations = unsetCopyWithValue,
  }) {
    return TextContent(
      text: text == unsetCopyWithValue ? this.text : text as String?,
      annotations: annotations == unsetCopyWithValue
          ? this.annotations
          : annotations as List<Annotation>?,
    );
  }
}
