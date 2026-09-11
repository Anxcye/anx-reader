import '../copy_with_sentinel.dart';

/// Segment of the content.
class Segment {
  /// The index of a Part object within its parent Content object.
  final int? partIndex;

  /// Start index in the given Part, measured in bytes.
  ///
  /// Offset from the start of the Part, inclusive, starting at zero.
  final int? startIndex;

  /// End index in the given Part, measured in bytes.
  ///
  /// Offset from the start of the Part, exclusive, starting at zero.
  final int? endIndex;

  /// The text corresponding to the segment from the response.
  final String? text;

  /// Creates a [Segment].
  const Segment({this.partIndex, this.startIndex, this.endIndex, this.text});

  /// Creates a [Segment] from JSON.
  factory Segment.fromJson(Map<String, dynamic> json) => Segment(
    partIndex: json['partIndex'] as int?,
    startIndex: json['startIndex'] as int?,
    endIndex: json['endIndex'] as int?,
    text: json['text'] as String?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (partIndex != null) 'partIndex': partIndex,
    if (startIndex != null) 'startIndex': startIndex,
    if (endIndex != null) 'endIndex': endIndex,
    if (text != null) 'text': text,
  };

  /// Creates a copy with replaced values.
  Segment copyWith({
    Object? partIndex = unsetCopyWithValue,
    Object? startIndex = unsetCopyWithValue,
    Object? endIndex = unsetCopyWithValue,
    Object? text = unsetCopyWithValue,
  }) {
    return Segment(
      partIndex: partIndex == unsetCopyWithValue
          ? this.partIndex
          : partIndex as int?,
      startIndex: startIndex == unsetCopyWithValue
          ? this.startIndex
          : startIndex as int?,
      endIndex: endIndex == unsetCopyWithValue
          ? this.endIndex
          : endIndex as int?,
      text: text == unsetCopyWithValue ? this.text : text as String?,
    );
  }

  @override
  String toString() =>
      'Segment(partIndex: $partIndex, startIndex: $startIndex, endIndex: $endIndex, text: $text)';
}
