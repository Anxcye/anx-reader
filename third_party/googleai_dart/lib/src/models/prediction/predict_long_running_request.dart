import '../copy_with_sentinel.dart';

/// Request message for PredictLongRunning operation.
///
/// Used for asynchronous prediction requests that return a long-running operation,
/// typically for video generation with Veo.
class PredictLongRunningRequest {
  /// Required. The instances that are the input to the prediction call.
  final List<dynamic> instances;

  /// Optional. The parameters that govern the prediction call.
  final dynamic parameters;

  /// Creates a [PredictLongRunningRequest].
  const PredictLongRunningRequest({required this.instances, this.parameters});

  /// Creates a [PredictLongRunningRequest] from JSON.
  factory PredictLongRunningRequest.fromJson(Map<String, dynamic> json) =>
      PredictLongRunningRequest(
        instances: json['instances'] as List<dynamic>? ?? [],
        parameters: json['parameters'],
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'instances': instances,
    if (parameters != null) 'parameters': parameters,
  };

  /// Creates a copy with replaced values.
  PredictLongRunningRequest copyWith({
    Object? instances = unsetCopyWithValue,
    Object? parameters = unsetCopyWithValue,
  }) {
    return PredictLongRunningRequest(
      instances: instances == unsetCopyWithValue
          ? this.instances
          : instances! as List<dynamic>,
      parameters: parameters == unsetCopyWithValue
          ? this.parameters
          : parameters,
    );
  }
}
