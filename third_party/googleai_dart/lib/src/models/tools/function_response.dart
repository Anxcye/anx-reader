import '../copy_with_sentinel.dart';

/// The result output from a function call.
class FunctionResponse {
  /// Optional ID of the function call this response is for.
  ///
  /// Used in Live API sessions to correlate responses with the original
  /// function call requests. Should match the [FunctionCall.id] of the
  /// call being responded to.
  final String? id;

  /// The name of the function that was called.
  final String name;

  /// The function response.
  final Map<String, dynamic> response;

  /// Creates a [FunctionResponse].
  const FunctionResponse({this.id, required this.name, required this.response});

  /// Creates a [FunctionResponse] from JSON.
  factory FunctionResponse.fromJson(Map<String, dynamic> json) =>
      FunctionResponse(
        id: json['id'] as String?,
        name: json['name'] as String,
        response: json['response'] as Map<String, dynamic>,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (id != null) 'id': id,
    'name': name,
    'response': response,
  };

  /// Creates a copy with replaced values.
  FunctionResponse copyWith({
    Object? id = unsetCopyWithValue,
    Object? name = unsetCopyWithValue,
    Object? response = unsetCopyWithValue,
  }) {
    return FunctionResponse(
      id: id == unsetCopyWithValue ? this.id : id as String?,
      name: name == unsetCopyWithValue ? this.name : name! as String,
      response: response == unsetCopyWithValue
          ? this.response
          : response! as Map<String, dynamic>,
    );
  }
}
