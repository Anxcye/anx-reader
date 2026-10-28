import '../copy_with_sentinel.dart';
import '../models/operation.dart';
import 'predict_long_running_metadata.dart';
import 'predict_long_running_response.dart';

/// Represents a long-running operation for video prediction.
///
/// This resource represents a long-running operation where metadata and response
/// fields are strongly typed for video generation predictions.
class PredictLongRunningOperation {
  /// The server-assigned name.
  final String? name;

  /// Metadata associated with the operation.
  final PredictLongRunningMetadata? metadata;

  /// If true, the operation is complete.
  final bool done;

  /// The error result if the operation failed.
  final OperationError? error;

  /// The normal response if the operation succeeded.
  final PredictLongRunningResponse? response;

  /// Creates a [PredictLongRunningOperation].
  const PredictLongRunningOperation({
    required this.done,
    this.name,
    this.metadata,
    this.error,
    this.response,
  });

  /// Creates a [PredictLongRunningOperation] from JSON.
  factory PredictLongRunningOperation.fromJson(Map<String, dynamic> json) =>
      PredictLongRunningOperation(
        name: json['name'] as String?,
        metadata: json['metadata'] != null
            ? PredictLongRunningMetadata.fromJson(
                json['metadata'] as Map<String, dynamic>,
              )
            : null,
        done: json['done'] as bool? ?? false,
        error: json['error'] != null
            ? OperationError.fromJson(json['error'] as Map<String, dynamic>)
            : null,
        response: json['response'] != null
            ? PredictLongRunningResponse.fromJson(
                json['response'] as Map<String, dynamic>,
              )
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (metadata != null) 'metadata': metadata!.toJson(),
    'done': done,
    if (error != null) 'error': error!.toJson(),
    if (response != null) 'response': response!.toJson(),
  };

  /// Creates a copy with replaced values.
  PredictLongRunningOperation copyWith({
    Object? name = unsetCopyWithValue,
    Object? metadata = unsetCopyWithValue,
    Object? done = unsetCopyWithValue,
    Object? error = unsetCopyWithValue,
    Object? response = unsetCopyWithValue,
  }) {
    return PredictLongRunningOperation(
      name: name == unsetCopyWithValue ? this.name : name as String?,
      metadata: metadata == unsetCopyWithValue
          ? this.metadata
          : metadata as PredictLongRunningMetadata?,
      done: done == unsetCopyWithValue ? this.done : done! as bool,
      error: error == unsetCopyWithValue
          ? this.error
          : error as OperationError?,
      response: response == unsetCopyWithValue
          ? this.response
          : response as PredictLongRunningResponse?,
    );
  }
}
