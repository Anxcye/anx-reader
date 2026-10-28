import '../copy_with_sentinel.dart';
import 'document_state.dart';

/// A collection of related content in a corpus.
///
/// Documents are hierarchical containers within a corpus or file search store.
///
/// Example name: `corpora/{corpus_id}/documents/my-awesome-doc-123a456b789c`
/// or: `fileSearchStores/{store_id}/documents/my-awesome-doc-123a456b789c`
class Document {
  /// Creates a new [Document] instance.
  const Document({
    this.name,
    this.displayName,
    this.createTime,
    this.updateTime,
    this.state,
    this.sizeBytes,
    this.mimeType,
  });

  /// The Document resource name.
  ///
  /// Immutable. Identifier.
  /// The ID can contain up to 40 lowercase alphanumeric or dash characters.
  ///
  /// Example: `corpora/{corpus_id}/documents/my-awesome-doc-123a456b789c`
  final String? name;

  /// Human-readable display name.
  ///
  /// The display name must be no more than 512 characters,
  /// including whitespace.
  ///
  /// Example: "Semantic Retriever Documentation"
  final String? displayName;

  /// Timestamp when the Document was created.
  ///
  /// Output only.
  final DateTime? createTime;

  /// Timestamp when the Document was last updated.
  ///
  /// Output only.
  final DateTime? updateTime;

  /// Current state of the Document.
  ///
  /// Output only.
  final DocumentState? state;

  /// The size of raw bytes ingested into the Document.
  ///
  /// Output only.
  final String? sizeBytes;

  /// The MIME type of the Document.
  ///
  /// Output only.
  final String? mimeType;

  /// Creates a [Document] from JSON.
  factory Document.fromJson(Map<String, dynamic> json) {
    return Document(
      name: json['name'] as String?,
      displayName: json['displayName'] as String?,
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'] as String)
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'] as String)
          : null,
      state: json['state'] != null
          ? DocumentState.fromString(json['state'] as String)
          : null,
      sizeBytes: json['sizeBytes'] as String?,
      mimeType: json['mimeType'] as String?,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (displayName != null) 'displayName': displayName,
      if (createTime != null) 'createTime': createTime!.toIso8601String(),
      if (updateTime != null) 'updateTime': updateTime!.toIso8601String(),
      if (state != null) 'state': state!.value,
      if (sizeBytes != null) 'sizeBytes': sizeBytes,
      if (mimeType != null) 'mimeType': mimeType,
    };
  }

  /// Creates a copy with replaced values.
  Document copyWith({
    Object? name = unsetCopyWithValue,
    Object? displayName = unsetCopyWithValue,
    Object? createTime = unsetCopyWithValue,
    Object? updateTime = unsetCopyWithValue,
    Object? state = unsetCopyWithValue,
    Object? sizeBytes = unsetCopyWithValue,
    Object? mimeType = unsetCopyWithValue,
  }) {
    return Document(
      name: name == unsetCopyWithValue ? this.name : name as String?,
      displayName: displayName == unsetCopyWithValue
          ? this.displayName
          : displayName as String?,
      createTime: createTime == unsetCopyWithValue
          ? this.createTime
          : createTime as DateTime?,
      updateTime: updateTime == unsetCopyWithValue
          ? this.updateTime
          : updateTime as DateTime?,
      state: state == unsetCopyWithValue ? this.state : state as DocumentState?,
      sizeBytes: sizeBytes == unsetCopyWithValue
          ? this.sizeBytes
          : sizeBytes as String?,
      mimeType: mimeType == unsetCopyWithValue
          ? this.mimeType
          : mimeType as String?,
    );
  }

  @override
  String toString() =>
      'Document('
      'name: $name, '
      'displayName: $displayName, '
      'createTime: $createTime, '
      'updateTime: $updateTime, '
      'state: $state, '
      'sizeBytes: $sizeBytes, '
      'mimeType: $mimeType)';
}
