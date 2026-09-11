import '../copy_with_sentinel.dart';
import '../generation/schema.dart';

/// Structured representation of a function declaration.
class FunctionDeclaration {
  /// The name of the function.
  final String name;

  /// Description of what the function does.
  final String description;

  /// Parameters for the function (as a Schema object).
  final Schema? parameters;

  /// Creates a [FunctionDeclaration].
  const FunctionDeclaration({
    required this.name,
    required this.description,
    this.parameters,
  });

  /// Creates a [FunctionDeclaration] from JSON.
  factory FunctionDeclaration.fromJson(Map<String, dynamic> json) =>
      FunctionDeclaration(
        name: json['name'] as String,
        description: json['description'] as String,
        parameters: json['parameters'] != null
            ? Schema.fromJson(json['parameters'] as Map<String, dynamic>)
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    'description': description,
    if (parameters != null) 'parameters': parameters!.toJson(),
  };

  /// Creates a copy with replaced values.
  FunctionDeclaration copyWith({
    Object? name = unsetCopyWithValue,
    Object? description = unsetCopyWithValue,
    Object? parameters = unsetCopyWithValue,
  }) {
    return FunctionDeclaration(
      name: name == unsetCopyWithValue ? this.name : name! as String,
      description: description == unsetCopyWithValue
          ? this.description
          : description! as String,
      parameters: parameters == unsetCopyWithValue
          ? this.parameters
          : parameters as Schema?,
    );
  }
}
