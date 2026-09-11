import '../copy_with_sentinel.dart';

/// Response for `ImportFile` to import a File API file with a `FileSearchStore`.
class ImportFileResponse {
  /// The name of the `FileSearchStore` containing `Document`s.
  ///
  /// Example: `fileSearchStores/my-file-search-store-123`
  final String? parent;

  /// Immutable. Identifier. The identifier for the `Document` imported.
  ///
  /// Example:
  /// `fileSearchStores/my-file-search-store-123/documents/my-awesome-doc-123a456b789c`
  final String? documentName;

  /// Creates an [ImportFileResponse].
  const ImportFileResponse({this.parent, this.documentName});

  /// Creates an [ImportFileResponse] from JSON.
  factory ImportFileResponse.fromJson(Map<String, dynamic> json) =>
      ImportFileResponse(
        parent: json['parent'] as String?,
        documentName: json['documentName'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (parent != null) 'parent': parent,
    if (documentName != null) 'documentName': documentName,
  };

  /// Creates a copy with replaced values.
  ImportFileResponse copyWith({
    Object? parent = unsetCopyWithValue,
    Object? documentName = unsetCopyWithValue,
  }) {
    return ImportFileResponse(
      parent: parent == unsetCopyWithValue ? this.parent : parent as String?,
      documentName: documentName == unsetCopyWithValue
          ? this.documentName
          : documentName as String?,
    );
  }

  @override
  String toString() =>
      'ImportFileResponse(parent: $parent, documentName: $documentName)';
}
