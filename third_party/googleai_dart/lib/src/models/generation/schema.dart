import '../copy_with_sentinel.dart';

/// Schema type.
enum SchemaType {
  /// Unspecified type.
  unspecified,

  /// String type.
  string,

  /// Number type.
  number,

  /// Integer type.
  integer,

  /// Boolean type.
  boolean,

  /// Array type.
  array,

  /// Object type.
  object,
}

/// Converts string to SchemaType enum.
SchemaType schemaTypeFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'STRING' => SchemaType.string,
    'NUMBER' => SchemaType.number,
    'INTEGER' => SchemaType.integer,
    'BOOLEAN' => SchemaType.boolean,
    'ARRAY' => SchemaType.array,
    'OBJECT' => SchemaType.object,
    _ => SchemaType.unspecified,
  };
}

/// Converts SchemaType enum to string.
String schemaTypeToString(SchemaType type) {
  return switch (type) {
    SchemaType.string => 'STRING',
    SchemaType.number => 'NUMBER',
    SchemaType.integer => 'INTEGER',
    SchemaType.boolean => 'BOOLEAN',
    SchemaType.array => 'ARRAY',
    SchemaType.object => 'OBJECT',
    SchemaType.unspecified => 'TYPE_UNSPECIFIED',
  };
}

/// Schema for structured data.
class Schema {
  /// The type of the property.
  final SchemaType? type;

  /// Format hint (e.g., "int32", "date-time").
  final String? format;

  /// Description of the property.
  final String? description;

  /// Whether the value can be null.
  final bool? nullable;

  /// Enum values.
  final List<String>? enumValues;

  /// Items schema for array type.
  final Schema? items;

  /// Properties for object type.
  final Map<String, Schema>? properties;

  /// Required properties for object type.
  final List<String>? required;

  /// Creates a [Schema].
  const Schema({
    this.type,
    this.format,
    this.description,
    this.nullable,
    this.enumValues,
    this.items,
    this.properties,
    this.required,
  });

  /// Creates a [Schema] from JSON.
  factory Schema.fromJson(Map<String, dynamic> json) => Schema(
    type: json['type'] != null
        ? schemaTypeFromString(json['type'] as String?)
        : null,
    format: json['format'] as String?,
    description: json['description'] as String?,
    nullable: json['nullable'] as bool?,
    enumValues: (json['enum'] as List?)?.cast<String>(),
    items: json['items'] != null
        ? Schema.fromJson(json['items'] as Map<String, dynamic>)
        : null,
    properties: json['properties'] != null
        ? (json['properties'] as Map<String, dynamic>).map(
            (k, v) => MapEntry(k, Schema.fromJson(v as Map<String, dynamic>)),
          )
        : null,
    required: (json['required'] as List?)?.cast<String>(),
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (type != null) 'type': schemaTypeToString(type!),
    if (format != null) 'format': format,
    if (description != null) 'description': description,
    if (nullable != null) 'nullable': nullable,
    if (enumValues != null) 'enum': enumValues,
    if (items != null) 'items': items!.toJson(),
    if (properties != null)
      'properties': properties!.map((k, v) => MapEntry(k, v.toJson())),
    if (required != null) 'required': required,
  };

  /// Creates a copy with replaced values.
  Schema copyWith({
    Object? type = unsetCopyWithValue,
    Object? format = unsetCopyWithValue,
    Object? description = unsetCopyWithValue,
    Object? nullable = unsetCopyWithValue,
    Object? enumValues = unsetCopyWithValue,
    Object? items = unsetCopyWithValue,
    Object? properties = unsetCopyWithValue,
    Object? required = unsetCopyWithValue,
  }) {
    return Schema(
      type: type == unsetCopyWithValue ? this.type : type as SchemaType?,
      format: format == unsetCopyWithValue ? this.format : format as String?,
      description: description == unsetCopyWithValue
          ? this.description
          : description as String?,
      nullable: nullable == unsetCopyWithValue
          ? this.nullable
          : nullable as bool?,
      enumValues: enumValues == unsetCopyWithValue
          ? this.enumValues
          : enumValues as List<String>?,
      items: items == unsetCopyWithValue ? this.items : items as Schema?,
      properties: properties == unsetCopyWithValue
          ? this.properties
          : properties as Map<String, Schema>?,
      required: required == unsetCopyWithValue
          ? this.required
          : required as List<String>?,
    );
  }
}
