part of 'tools.dart';

/// A function tool that can be called by the model.
class FunctionTool extends InteractionTool {
  @override
  String get type => 'function';

  /// The name of the function.
  final String? name;

  /// A description of the function.
  final String? description;

  /// The JSON Schema for the function's parameters.
  final Map<String, dynamic>? parameters;

  /// Creates a [FunctionTool] instance.
  const FunctionTool({this.name, this.description, this.parameters});

  /// Creates a [FunctionTool] from JSON.
  factory FunctionTool.fromJson(Map<String, dynamic> json) => FunctionTool(
    name: json['name'] as String?,
    description: json['description'] as String?,
    parameters: json['parameters'] as Map<String, dynamic>?,
  );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (name != null) 'name': name,
    if (description != null) 'description': description,
    if (parameters != null) 'parameters': parameters,
  };
}
