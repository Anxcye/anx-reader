import '../copy_with_sentinel.dart';

/// Represents a long-running operation.
class Operation {
  /// The server-assigned name.
  final String? name;

  /// Service-specific metadata associated with the operation.
  final Map<String, dynamic>? metadata;

  /// If true, the operation is complete.
  final bool done;

  /// The error result if the operation failed.
  final OperationError? error;

  /// The normal response if the operation succeeded.
  final Map<String, dynamic>? response;

  /// Creates an [Operation].
  const Operation({
    required this.done,
    this.name,
    this.metadata,
    this.error,
    this.response,
  });

  /// Creates an [Operation] from JSON.
  factory Operation.fromJson(Map<String, dynamic> json) => Operation(
    name: json['name'] as String?,
    metadata: json['metadata'] as Map<String, dynamic>?,
    done: json['done'] as bool? ?? false,
    error: json['error'] != null
        ? OperationError.fromJson(json['error'] as Map<String, dynamic>)
        : null,
    response: json['response'] as Map<String, dynamic>?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (metadata != null) 'metadata': metadata,
    'done': done,
    if (error != null) 'error': error!.toJson(),
    if (response != null) 'response': response,
  };

  /// Creates a copy with replaced values.
  Operation copyWith({
    Object? name = unsetCopyWithValue,
    Object? metadata = unsetCopyWithValue,
    Object? done = unsetCopyWithValue,
    Object? error = unsetCopyWithValue,
    Object? response = unsetCopyWithValue,
  }) {
    return Operation(
      name: name == unsetCopyWithValue ? this.name : name as String?,
      metadata: metadata == unsetCopyWithValue
          ? this.metadata
          : metadata as Map<String, dynamic>?,
      done: done == unsetCopyWithValue ? this.done : done! as bool,
      error: error == unsetCopyWithValue
          ? this.error
          : error as OperationError?,
      response: response == unsetCopyWithValue
          ? this.response
          : response as Map<String, dynamic>?,
    );
  }
}

/// Error information for a failed operation.
class OperationError {
  /// Error code.
  final int code;

  /// Error message.
  final String message;

  /// Additional error details.
  final List<dynamic>? details;

  /// Creates an [OperationError].
  const OperationError({
    required this.code,
    required this.message,
    this.details,
  });

  /// Creates an [OperationError] from JSON.
  factory OperationError.fromJson(Map<String, dynamic> json) => OperationError(
    code: json['code'] as int,
    message: json['message'] as String,
    details: json['details'] as List<dynamic>?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'code': code,
    'message': message,
    if (details != null) 'details': details,
  };

  /// Creates a copy with replaced values.
  OperationError copyWith({
    Object? code = unsetCopyWithValue,
    Object? message = unsetCopyWithValue,
    Object? details = unsetCopyWithValue,
  }) {
    return OperationError(
      code: code == unsetCopyWithValue ? this.code : code! as int,
      message: message == unsetCopyWithValue
          ? this.message
          : message! as String,
      details: details == unsetCopyWithValue
          ? this.details
          : details as List<dynamic>?,
    );
  }
}
