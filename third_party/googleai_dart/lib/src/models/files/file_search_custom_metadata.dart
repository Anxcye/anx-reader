import '../copy_with_sentinel.dart';

/// User-provided custom metadata stored as key-value pairs for file search.
class FileSearchCustomMetadata {
  /// Required. The key of the metadata to store.
  final String key;

  /// The string value of the metadata to store.
  final String? stringValue;

  /// The numeric value of the metadata to store.
  final double? numericValue;

  /// The StringList value of the metadata to store.
  final List<String>? stringListValue;

  /// Creates a [FileSearchCustomMetadata].
  const FileSearchCustomMetadata({
    required this.key,
    this.stringValue,
    this.numericValue,
    this.stringListValue,
  });

  /// Creates a [FileSearchCustomMetadata] from JSON.
  factory FileSearchCustomMetadata.fromJson(
    Map<String, dynamic> json,
  ) => FileSearchCustomMetadata(
    key: json['key'] as String,
    stringValue: json['stringValue'] as String?,
    numericValue: (json['numericValue'] as num?)?.toDouble(),
    stringListValue:
        (json['stringListValue'] as Map<String, dynamic>?)?['values'] != null
        ? ((json['stringListValue'] as Map<String, dynamic>)['values'] as List)
              .map((e) => e as String)
              .toList()
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'key': key,
    if (stringValue != null) 'stringValue': stringValue,
    if (numericValue != null) 'numericValue': numericValue,
    if (stringListValue != null) 'stringListValue': {'values': stringListValue},
  };

  /// Creates a copy with replaced values.
  FileSearchCustomMetadata copyWith({
    String? key,
    Object? stringValue = unsetCopyWithValue,
    Object? numericValue = unsetCopyWithValue,
    Object? stringListValue = unsetCopyWithValue,
  }) {
    return FileSearchCustomMetadata(
      key: key ?? this.key,
      stringValue: stringValue == unsetCopyWithValue
          ? this.stringValue
          : stringValue as String?,
      numericValue: numericValue == unsetCopyWithValue
          ? this.numericValue
          : numericValue as double?,
      stringListValue: stringListValue == unsetCopyWithValue
          ? this.stringListValue
          : stringListValue as List<String>?,
    );
  }

  @override
  String toString() =>
      'FileSearchCustomMetadata(key: $key, stringValue: $stringValue, numericValue: $numericValue, stringListValue: $stringListValue)';
}
