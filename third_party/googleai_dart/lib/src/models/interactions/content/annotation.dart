part of 'content.dart';

/// Citation information for model-generated content.
class Annotation {
  /// Start of segment of the response that is attributed to this source.
  /// Index indicates the start of the segment, measured in bytes.
  final int? startIndex;

  /// End of the attributed segment, exclusive.
  final int? endIndex;

  /// Source attributed for a portion of the text. Could be a URL, title, or
  /// other identifier.
  final String? source;

  /// Creates an [Annotation] instance.
  const Annotation({this.startIndex, this.endIndex, this.source});

  /// Creates an [Annotation] from JSON.
  factory Annotation.fromJson(Map<String, dynamic> json) => Annotation(
    startIndex: json['start_index'] as int?,
    endIndex: json['end_index'] as int?,
    source: json['source'] as String?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (startIndex != null) 'start_index': startIndex,
    if (endIndex != null) 'end_index': endIndex,
    if (source != null) 'source': source,
  };

  /// Creates a copy with replaced values.
  Annotation copyWith({
    Object? startIndex = unsetCopyWithValue,
    Object? endIndex = unsetCopyWithValue,
    Object? source = unsetCopyWithValue,
  }) {
    return Annotation(
      startIndex: startIndex == unsetCopyWithValue
          ? this.startIndex
          : startIndex as int?,
      endIndex: endIndex == unsetCopyWithValue
          ? this.endIndex
          : endIndex as int?,
      source: source == unsetCopyWithValue ? this.source : source as String?,
    );
  }
}
