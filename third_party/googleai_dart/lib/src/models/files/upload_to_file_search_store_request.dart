import '../copy_with_sentinel.dart';
import 'chunking_config.dart';
import 'file_search_custom_metadata.dart';

/// Request for `UploadToFileSearchStore`.
class UploadToFileSearchStoreRequest {
  /// Optional. Display name of the created document.
  final String? displayName;

  /// Custom metadata to be associated with the data.
  final List<FileSearchCustomMetadata>? customMetadata;

  /// Optional. Config for telling the service how to chunk the data.
  ///
  /// If not provided, the service will use default parameters.
  final ChunkingConfig? chunkingConfig;

  /// Optional. MIME type of the data.
  ///
  /// If not provided, it will be inferred from the uploaded content.
  final String? mimeType;

  /// Creates an [UploadToFileSearchStoreRequest].
  const UploadToFileSearchStoreRequest({
    this.displayName,
    this.customMetadata,
    this.chunkingConfig,
    this.mimeType,
  });

  /// Creates an [UploadToFileSearchStoreRequest] from JSON.
  factory UploadToFileSearchStoreRequest.fromJson(Map<String, dynamic> json) =>
      UploadToFileSearchStoreRequest(
        displayName: json['displayName'] as String?,
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
        mimeType: json['mimeType'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (displayName != null) 'displayName': displayName,
    if (customMetadata != null)
      'customMetadata': customMetadata!.map((e) => e.toJson()).toList(),
    if (chunkingConfig != null) 'chunkingConfig': chunkingConfig!.toJson(),
    if (mimeType != null) 'mimeType': mimeType,
  };

  /// Creates a copy with replaced values.
  UploadToFileSearchStoreRequest copyWith({
    Object? displayName = unsetCopyWithValue,
    Object? customMetadata = unsetCopyWithValue,
    Object? chunkingConfig = unsetCopyWithValue,
    Object? mimeType = unsetCopyWithValue,
  }) {
    return UploadToFileSearchStoreRequest(
      displayName: displayName == unsetCopyWithValue
          ? this.displayName
          : displayName as String?,
      customMetadata: customMetadata == unsetCopyWithValue
          ? this.customMetadata
          : customMetadata as List<FileSearchCustomMetadata>?,
      chunkingConfig: chunkingConfig == unsetCopyWithValue
          ? this.chunkingConfig
          : chunkingConfig as ChunkingConfig?,
      mimeType: mimeType == unsetCopyWithValue
          ? this.mimeType
          : mimeType as String?,
    );
  }

  @override
  String toString() =>
      'UploadToFileSearchStoreRequest(displayName: $displayName, customMetadata: $customMetadata, chunkingConfig: $chunkingConfig, mimeType: $mimeType)';
}
