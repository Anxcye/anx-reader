part of 'deltas.dart';

/// A function call delta update.
class FunctionCallDelta extends InteractionDelta {
  @override
  String get type => 'function_call';

  /// A unique ID for this specific tool call.
  final String? id;

  /// The name of the function to call.
  final String? name;

  /// The arguments to pass to the function.
  final Map<String, dynamic>? arguments;

  /// Creates a [FunctionCallDelta] instance.
  const FunctionCallDelta({this.id, this.name, this.arguments});

  /// Creates a [FunctionCallDelta] from JSON.
  factory FunctionCallDelta.fromJson(Map<String, dynamic> json) =>
      FunctionCallDelta(
        id: json['id'] as String?,
        name: json['name'] as String?,
        arguments: json['arguments'] as Map<String, dynamic>?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    if (name != null) 'name': name,
    if (arguments != null) 'arguments': arguments,
  };
}
