import '../copy_with_sentinel.dart';
import 'inlined_embed_content_requests.dart';

/// Configures the input to an embed batch request.
///
/// Either [fileName] or [requests] must be set, but not both.
class InputEmbedContentConfig {
  /// The name of the `File` containing the input requests.
  ///
  /// The file should contain one request per line in JSONL format.
  final String? fileName;

  /// The requests to be processed in the batch (inline).
  final InlinedEmbedContentRequests? requests;

  /// Creates an [InputEmbedContentConfig].
  const InputEmbedContentConfig({this.fileName, this.requests});

  /// Creates an [InputEmbedContentConfig] from JSON.
  factory InputEmbedContentConfig.fromJson(Map<String, dynamic> json) =>
      InputEmbedContentConfig(
        fileName: json['fileName'] as String?,
        requests: json['requests'] != null
            ? InlinedEmbedContentRequests.fromJson(
                json['requests'] as Map<String, dynamic>,
              )
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (fileName != null) 'fileName': fileName,
    if (requests != null) 'requests': requests!.toJson(),
  };

  /// Creates a copy with replaced values.
  InputEmbedContentConfig copyWith({
    Object? fileName = unsetCopyWithValue,
    Object? requests = unsetCopyWithValue,
  }) {
    return InputEmbedContentConfig(
      fileName: fileName == unsetCopyWithValue
          ? this.fileName
          : fileName as String?,
      requests: requests == unsetCopyWithValue
          ? this.requests
          : requests as InlinedEmbedContentRequests?,
    );
  }
}
