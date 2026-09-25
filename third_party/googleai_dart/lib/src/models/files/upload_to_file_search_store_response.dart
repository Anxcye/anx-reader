import '../copy_with_sentinel.dart';

/// Response from UploadToFileSearchStore.
class UploadToFileSearchStoreResponse {
  /// The name of the `FileSearchStore` containing `Document`s.
  ///
  /// Example: `fileSearchStores/my-file-search-store-123`
  final String? parent;

  /// Immutable. Identifier. The identifier for the `Document` imported.
  ///
  /// Example: `fileSearchStores/my-file-search-store-123a456b789c`
  final String? documentName;

  /// MIME type of the file.
  final String? mimeType;

  /// Size of the file in bytes.
  final String? sizeBytes;

  /// Creates an [UploadToFileSearchStoreResponse].
  const UploadToFileSearchStoreResponse({
    this.parent,
    this.documentName,
    this.mimeType,
    this.sizeBytes,
  });

  /// Creates an [UploadToFileSearchStoreResponse] from JSON.
  factory UploadToFileSearchStoreResponse.fromJson(Map<String, dynamic> json) =>
      UploadToFileSearchStoreResponse(
        parent: json['parent'] as String?,
        documentName: json['documentName'] as String?,
        mimeType: json['mimeType'] as String?,
        sizeBytes: json['sizeBytes'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (parent != null) 'parent': parent,
    if (documentName != null) 'documentName': documentName,
    if (mimeType != null) 'mimeType': mimeType,
    if (sizeBytes != null) 'sizeBytes': sizeBytes,
  };

  /// Creates a copy with replaced values.
  UploadToFileSearchStoreResponse copyWith({
    Object? parent = unsetCopyWithValue,
    Object? documentName = unsetCopyWithValue,
    Object? mimeType = unsetCopyWithValue,
    Object? sizeBytes = unsetCopyWithValue,
  }) {
    return UploadToFileSearchStoreResponse(
      parent: parent == unsetCopyWithValue ? this.parent : parent as String?,
      documentName: documentName == unsetCopyWithValue
          ? this.documentName
          : documentName as String?,
      mimeType: mimeType == unsetCopyWithValue
          ? this.mimeType
          : mimeType as String?,
      sizeBytes: sizeBytes == unsetCopyWithValue
          ? this.sizeBytes
          : sizeBytes as String?,
    );
  }

  @override
  String toString() =>
      'UploadToFileSearchStoreResponse(parent: $parent, documentName: $documentName, mimeType: $mimeType, sizeBytes: $sizeBytes)';
}
