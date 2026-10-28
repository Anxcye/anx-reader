import '../copy_with_sentinel.dart';

/// Response message for Predict operation.
///
/// Contains the prediction outputs from the model.
class PredictResponse {
  /// The outputs of the prediction call.
  final List<dynamic> predictions;

  /// Creates a [PredictResponse].
  const PredictResponse({required this.predictions});

  /// Creates a [PredictResponse] from JSON.
  factory PredictResponse.fromJson(Map<String, dynamic> json) =>
      PredictResponse(predictions: json['predictions'] as List<dynamic>? ?? []);

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {'predictions': predictions};

  /// Creates a copy with replaced values.
  PredictResponse copyWith({Object? predictions = unsetCopyWithValue}) {
    return PredictResponse(
      predictions: predictions == unsetCopyWithValue
          ? this.predictions
          : predictions! as List<dynamic>,
    );
  }
}
