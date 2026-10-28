import '../copy_with_sentinel.dart';
import '../generation/generate_content_response.dart';
import 'status.dart';

/// A single response in a batch with optional metadata and error.
class InlinedResponse {
  /// The error encountered while processing the request (if any).
  final Status? error;

  /// The response to the request (if successful).
  final GenerateContentResponse? response;

  /// Metadata associated with the request.
  final Map<String, dynamic>? metadata;

  /// Creates an [InlinedResponse].
  const InlinedResponse({this.error, this.response, this.metadata});

  /// Creates an [InlinedResponse] from JSON.
  factory InlinedResponse.fromJson(Map<String, dynamic> json) =>
      InlinedResponse(
        error: json['error'] != null
            ? Status.fromJson(json['error'] as Map<String, dynamic>)
            : null,
        response: json['response'] != null
            ? GenerateContentResponse.fromJson(
                json['response'] as Map<String, dynamic>,
              )
            : null,
        metadata: json['metadata'] as Map<String, dynamic>?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (error != null) 'error': error!.toJson(),
    if (response != null) 'response': response!.toJson(),
    if (metadata != null) 'metadata': metadata,
  };

  /// Creates a copy with replaced values.
  InlinedResponse copyWith({
    Object? error = unsetCopyWithValue,
    Object? response = unsetCopyWithValue,
    Object? metadata = unsetCopyWithValue,
  }) {
    return InlinedResponse(
      error: error == unsetCopyWithValue ? this.error : error as Status?,
      response: response == unsetCopyWithValue
          ? this.response
          : response as GenerateContentResponse?,
      metadata: metadata == unsetCopyWithValue
          ? this.metadata
          : metadata as Map<String, dynamic>?,
    );
  }
}
