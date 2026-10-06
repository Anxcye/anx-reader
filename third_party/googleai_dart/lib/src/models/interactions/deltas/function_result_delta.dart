part of 'deltas.dart';

/// A function result delta update.
class FunctionResultDelta extends InteractionDelta {
  @override
  String get type => 'function_result';

  /// The name of the function.
  final String? name;

  /// The result of the function call.
  final Object? result;

  /// Whether the function call resulted in an error.
  final bool? isError;

  /// Creates a [FunctionResultDelta] instance.
  const FunctionResultDelta({this.name, this.result, this.isError});

  /// Creates a [FunctionResultDelta] from JSON.
  factory FunctionResultDelta.fromJson(Map<String, dynamic> json) =>
      FunctionResultDelta(
        name: json['name'] as String?,
        result: json['result'],
        isError: json['is_error'] as bool?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (name != null) 'name': name,
    if (result != null) 'result': result,
    if (isError != null) 'is_error': isError,
  };
}
