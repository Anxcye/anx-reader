import '../copy_with_sentinel.dart';

/// A predicted function call returned from the model.
class FunctionCall {
  /// Optional unique ID of the function call for correlation.
  ///
  /// Used in Live API sessions to match tool call responses to requests
  /// and to identify calls in cancellation messages.
  final String? id;

  /// The name of the function to call.
  final String name;

  /// The function parameters and values.
  final Map<String, dynamic>? args;

  /// Creates a [FunctionCall].
  const FunctionCall({this.id, required this.name, this.args});

  /// Creates a [FunctionCall] from JSON.
  factory FunctionCall.fromJson(Map<String, dynamic> json) => FunctionCall(
    id: json['id'] as String?,
    name: json['name'] as String,
    args: json['args'] as Map<String, dynamic>?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    if (args != null) 'args': args,
  };

  /// Creates a copy with replaced values.
  FunctionCall copyWith({
    Object? id = unsetCopyWithValue,
    Object? name = unsetCopyWithValue,
    Object? args = unsetCopyWithValue,
  }) {
    return FunctionCall(
      id: id == unsetCopyWithValue ? this.id : id as String?,
      name: name == unsetCopyWithValue ? this.name : name! as String,
      args: args == unsetCopyWithValue
          ? this.args
          : args as Map<String, dynamic>?,
    );
  }
}
