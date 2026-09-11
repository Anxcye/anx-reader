import '../copy_with_sentinel.dart';
import 'inlined_requests.dart';

/// Configures the input to a batch request.
///
/// Either [fileName] or [requests] must be set, but not both.
class InputConfig {
  /// The name of the `File` containing the input requests.
  ///
  /// The file should contain one request per line in JSONL format.
  final String? fileName;

  /// The requests to be processed in the batch (inline).
  final InlinedRequests? requests;

  /// Creates an [InputConfig].
  const InputConfig({this.fileName, this.requests});

  /// Creates an [InputConfig] from JSON.
  factory InputConfig.fromJson(Map<String, dynamic> json) => InputConfig(
    fileName: json['fileName'] as String?,
    requests: json['requests'] != null
        ? InlinedRequests.fromJson(json['requests'] as Map<String, dynamic>)
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (fileName != null) 'fileName': fileName,
    if (requests != null) 'requests': requests!.toJson(),
  };

  /// Creates a copy with replaced values.
  InputConfig copyWith({
    Object? fileName = unsetCopyWithValue,
    Object? requests = unsetCopyWithValue,
  }) {
    return InputConfig(
      fileName: fileName == unsetCopyWithValue
          ? this.fileName
          : fileName as String?,
      requests: requests == unsetCopyWithValue
          ? this.requests
          : requests as InlinedRequests?,
    );
  }
}
