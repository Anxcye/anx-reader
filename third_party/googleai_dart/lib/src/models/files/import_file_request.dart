import '../copy_with_sentinel.dart';
import 'chunking_config.dart';
import 'file_search_custom_metadata.dart';

/// Request for `ImportFile` to import a File API file with a `FileSearchStore`.
class ImportFileRequest {
  /// Required. The name of the `File` to import.
  ///
  /// Example: `files/abc-123`
  final String fileName;

  /// Custom metadata to be associated with the file.
  final List<FileSearchCustomMetadata>? customMetadata;

  /// Optional. Config for telling the service how to chunk the file.
  ///
  /// If not provided, the service will use default parameters.
  final ChunkingConfig? chunkingConfig;

  /// Creates an [ImportFileRequest].
  const ImportFileRequest({
    required this.fileName,
    this.customMetadata,
    this.chunkingConfig,
  });

  /// Creates an [ImportFileRequest] from JSON.
  factory ImportFileRequest.fromJson(Map<String, dynamic> json) =>
      ImportFileRequest(
        fileName: json['fileName'] as String,
        customMetadata: (json['customMetadata'] as List?)
            ?.map(
              (e) =>
                  FileSearchCustomMetadata.fromJson(e as Map<String, dynamic>),
            )
            .toList(),
        chunkingConfig: json['chunkingConfig'] != null
            ? ChunkingConfig.fromJson(
                json['chunkingConfig'] as Map<String, dynamic>,
              )
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'fileName': fileName,
    if (customMetadata != null)
      'customMetadata': customMetadata!.map((e) => e.toJson()).toList(),
    if (chunkingConfig != null) 'chunkingConfig': chunkingConfig!.toJson(),
  };

  /// Creates a copy with replaced values.
  ImportFileRequest copyWith({
    String? fileName,
    Object? customMetadata = unsetCopyWithValue,
    Object? chunkingConfig = unsetCopyWithValue,
  }) {
    return ImportFileRequest(
      fileName: fileName ?? this.fileName,
      customMetadata: customMetadata == unsetCopyWithValue
          ? this.customMetadata
          : customMetadata as List<FileSearchCustomMetadata>?,
      chunkingConfig: chunkingConfig == unsetCopyWithValue
          ? this.chunkingConfig
          : chunkingConfig as ChunkingConfig?,
    );
  }

  @override
  String toString() =>
      'ImportFileRequest(fileName: $fileName, customMetadata: $customMetadata, chunkingConfig: $chunkingConfig)';
}
