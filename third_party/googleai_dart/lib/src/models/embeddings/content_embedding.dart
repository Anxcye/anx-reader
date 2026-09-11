import '../copy_with_sentinel.dart';

/// An embedding for a piece of content.
class ContentEmbedding {
  /// The embedding values.
  final List<double> values;

  /// The shape of the embedding (dimensions).
  final List<int>? shape;

  /// Creates a [ContentEmbedding].
  const ContentEmbedding({required this.values, this.shape});

  /// Creates a [ContentEmbedding] from JSON.
  factory ContentEmbedding.fromJson(Map<String, dynamic> json) =>
      ContentEmbedding(
        values: ((json['values'] as List?) ?? [])
            .map((e) => (e as num).toDouble())
            .toList(),
        shape: (json['shape'] as List?)?.map((e) => e as int).toList(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'values': values,
    if (shape != null) 'shape': shape,
  };

  /// Creates a copy with replaced values.
  ContentEmbedding copyWith({
    Object? values = unsetCopyWithValue,
    Object? shape = unsetCopyWithValue,
  }) {
    return ContentEmbedding(
      values: values == unsetCopyWithValue
          ? this.values
          : values! as List<double>,
      shape: shape == unsetCopyWithValue ? this.shape : shape as List<int>?,
    );
  }
}
