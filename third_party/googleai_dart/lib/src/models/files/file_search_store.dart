import '../copy_with_sentinel.dart';

/// A `FileSearchStore` is a collection of `Document`s.
class FileSearchStore {
  /// Output only. Immutable. The `FileSearchStore` resource name.
  ///
  /// It is an ID (name excluding the "fileSearchStores/" prefix) that can
  /// contain up to 40 characters that are lowercase alphanumeric or dashes (-).
  ///
  /// Example: `fileSearchStores/my-awesome-file-search-store-123a456b789c`
  final String? name;

  /// Optional. The human-readable display name for the `FileSearchStore`.
  ///
  /// The display name must be no more than 512 characters in length,
  /// including spaces. Example: "Docs on Semantic Retriever"
  final String? displayName;

  /// Output only. The Timestamp of when the `FileSearchStore` was created.
  final DateTime? createTime;

  /// Output only. The Timestamp of when the `FileSearchStore` was last updated.
  final DateTime? updateTime;

  /// Output only. The number of documents in the `FileSearchStore` that are
  /// active and ready for retrieval.
  final String? activeDocumentsCount;

  /// Output only. The number of documents in the `FileSearchStore` that are
  /// being processed.
  final String? pendingDocumentsCount;

  /// Output only. The number of documents in the `FileSearchStore` that have
  /// failed processing.
  final String? failedDocumentsCount;

  /// Output only. The size of raw bytes ingested into the `FileSearchStore`.
  ///
  /// This is the total size of all the documents in the `FileSearchStore`.
  final String? sizeBytes;

  /// Creates a [FileSearchStore].
  const FileSearchStore({
    this.name,
    this.displayName,
    this.createTime,
    this.updateTime,
    this.activeDocumentsCount,
    this.pendingDocumentsCount,
    this.failedDocumentsCount,
    this.sizeBytes,
  });

  /// Creates a [FileSearchStore] from JSON.
  factory FileSearchStore.fromJson(Map<String, dynamic> json) =>
      FileSearchStore(
        name: json['name'] as String?,
        displayName: json['displayName'] as String?,
        createTime: json['createTime'] != null
            ? DateTime.parse(json['createTime'] as String)
            : null,
        updateTime: json['updateTime'] != null
            ? DateTime.parse(json['updateTime'] as String)
            : null,
        activeDocumentsCount: json['activeDocumentsCount'] as String?,
        pendingDocumentsCount: json['pendingDocumentsCount'] as String?,
        failedDocumentsCount: json['failedDocumentsCount'] as String?,
        sizeBytes: json['sizeBytes'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (displayName != null) 'displayName': displayName,
    if (createTime != null) 'createTime': createTime!.toIso8601String(),
    if (updateTime != null) 'updateTime': updateTime!.toIso8601String(),
    if (activeDocumentsCount != null)
      'activeDocumentsCount': activeDocumentsCount,
    if (pendingDocumentsCount != null)
      'pendingDocumentsCount': pendingDocumentsCount,
    if (failedDocumentsCount != null)
      'failedDocumentsCount': failedDocumentsCount,
    if (sizeBytes != null) 'sizeBytes': sizeBytes,
  };

  /// Creates a copy with replaced values.
  FileSearchStore copyWith({
    Object? name = unsetCopyWithValue,
    Object? displayName = unsetCopyWithValue,
    Object? createTime = unsetCopyWithValue,
    Object? updateTime = unsetCopyWithValue,
    Object? activeDocumentsCount = unsetCopyWithValue,
    Object? pendingDocumentsCount = unsetCopyWithValue,
    Object? failedDocumentsCount = unsetCopyWithValue,
    Object? sizeBytes = unsetCopyWithValue,
  }) {
    return FileSearchStore(
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
      activeDocumentsCount: activeDocumentsCount == unsetCopyWithValue
          ? this.activeDocumentsCount
          : activeDocumentsCount as String?,
      pendingDocumentsCount: pendingDocumentsCount == unsetCopyWithValue
          ? this.pendingDocumentsCount
          : pendingDocumentsCount as String?,
      failedDocumentsCount: failedDocumentsCount == unsetCopyWithValue
          ? this.failedDocumentsCount
          : failedDocumentsCount as String?,
      sizeBytes: sizeBytes == unsetCopyWithValue
          ? this.sizeBytes
          : sizeBytes as String?,
    );
  }

  @override
  String toString() =>
      'FileSearchStore(name: $name, displayName: $displayName, createTime: $createTime, updateTime: $updateTime, activeDocumentsCount: $activeDocumentsCount, pendingDocumentsCount: $pendingDocumentsCount, failedDocumentsCount: $failedDocumentsCount, sizeBytes: $sizeBytes)';
}
