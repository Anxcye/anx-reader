import '../copy_with_sentinel.dart';

/// Request message for Predict operation.
///
/// Used for synchronous prediction requests to models like Veo for video generation.
class PredictRequest {
  /// Required. The instances that are the input to the prediction call.
  final List<dynamic> instances;

  /// Optional. The parameters that govern the prediction call.
  final dynamic parameters;

  /// Creates a [PredictRequest].
  const PredictRequest({required this.instances, this.parameters});

  /// Creates a [PredictRequest] from JSON.
  factory PredictRequest.fromJson(Map<String, dynamic> json) => PredictRequest(
    instances: json['instances'] as List<dynamic>? ?? [],
    parameters: json['parameters'],
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'instances': instances,
    if (parameters != null) 'parameters': parameters,
  };

  /// Creates a copy with replaced values.
  PredictRequest copyWith({
    Object? instances = unsetCopyWithValue,
    Object? parameters = unsetCopyWithValue,
  }) {
    return PredictRequest(
      instances: instances == unsetCopyWithValue
          ? this.instances
          : instances! as List<dynamic>,
      parameters: parameters == unsetCopyWithValue
          ? this.parameters
          : parameters,
    );
  }
}
