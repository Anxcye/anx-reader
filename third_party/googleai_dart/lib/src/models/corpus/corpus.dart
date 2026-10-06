import '../copy_with_sentinel.dart';

/// A collection of Documents.
///
/// A project can create up to 10 corpora.
///
/// Example name: `corpora/my-awesome-corpora-123a456b789c`
class Corpus {
  /// Creates a new [Corpus] instance.
  const Corpus({this.name, this.displayName, this.createTime, this.updateTime});

  /// The Corpus resource name.
  ///
  /// Output only. Immutable. Identifier.
  /// The ID can contain up to 40 lowercase alphanumeric or dash characters.
  ///
  /// Example: `corpora/my-awesome-corpora-123a456b789c`
  final String? name;

  /// Human-readable display name.
  ///
  /// The display name must be no more than 512 characters,
  /// including whitespace.
  ///
  /// Example: "Docs on Semantic Retriever"
  final String? displayName;

  /// Timestamp when the Corpus was created.
  ///
  /// Output only.
  final DateTime? createTime;

  /// Timestamp when the Corpus was last updated.
  ///
  /// Output only.
  final DateTime? updateTime;

  /// Creates a [Corpus] from JSON.
  factory Corpus.fromJson(Map<String, dynamic> json) {
    return Corpus(
      name: json['name'] as String?,
      displayName: json['displayName'] as String?,
      createTime: json['createTime'] != null
          ? DateTime.parse(json['createTime'] as String)
          : null,
      updateTime: json['updateTime'] != null
          ? DateTime.parse(json['updateTime'] as String)
          : null,
    );
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson() {
    return {
      if (name != null) 'name': name,
      if (displayName != null) 'displayName': displayName,
      if (createTime != null) 'createTime': createTime!.toIso8601String(),
      if (updateTime != null) 'updateTime': updateTime!.toIso8601String(),
    };
  }

  /// Creates a copy with replaced values.
  Corpus copyWith({
    Object? name = unsetCopyWithValue,
    Object? displayName = unsetCopyWithValue,
    Object? createTime = unsetCopyWithValue,
    Object? updateTime = unsetCopyWithValue,
  }) {
    return Corpus(
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
    );
  }

  @override
  String toString() =>
      'Corpus('
      'name: $name, '
      'displayName: $displayName, '
      'createTime: $createTime, '
      'updateTime: $updateTime)';
}
