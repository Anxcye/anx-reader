import '../copy_with_sentinel.dart';

/// Hyperparameters for tuning a model.
class Hyperparameters {
  /// The number of training epochs.
  final int? epochCount;

  /// The batch size for training.
  final int? batchSize;

  /// The learning rate for training.
  final double? learningRate;

  /// Creates a [Hyperparameters].
  const Hyperparameters({this.epochCount, this.batchSize, this.learningRate});

  /// Creates a [Hyperparameters] from JSON.
  factory Hyperparameters.fromJson(Map<String, dynamic> json) =>
      Hyperparameters(
        epochCount: json['epochCount'] as int?,
        batchSize: json['batchSize'] as int?,
        learningRate: (json['learningRate'] as num?)?.toDouble(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (epochCount != null) 'epochCount': epochCount,
    if (batchSize != null) 'batchSize': batchSize,
    if (learningRate != null) 'learningRate': learningRate,
  };

  /// Creates a copy with replaced values.
  Hyperparameters copyWith({
    Object? epochCount = unsetCopyWithValue,
    Object? batchSize = unsetCopyWithValue,
    Object? learningRate = unsetCopyWithValue,
  }) {
    return Hyperparameters(
      epochCount: epochCount == unsetCopyWithValue
          ? this.epochCount
          : epochCount as int?,
      batchSize: batchSize == unsetCopyWithValue
          ? this.batchSize
          : batchSize as int?,
      learningRate: learningRate == unsetCopyWithValue
          ? this.learningRate
          : learningRate as double?,
    );
  }
}
