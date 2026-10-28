import '../copy_with_sentinel.dart';

/// Error status information for RPC APIs.
///
/// The `Status` type defines a logical error model that is suitable for
/// different programming environments, including REST APIs and RPC APIs.
class Status {
  /// The status code (e.g., HTTP status code).
  final int? code;

  /// A developer-facing error message in English.
  final String? message;

  /// A list of messages that carry the error details.
  final List<Map<String, dynamic>>? details;

  /// Creates a [Status].
  const Status({this.code, this.message, this.details});

  /// Creates a [Status] from JSON.
  factory Status.fromJson(Map<String, dynamic> json) => Status(
    code: json['code'] as int?,
    message: json['message'] as String?,
    details: json['details'] != null
        ? (json['details'] as List)
              .map((e) => e as Map<String, dynamic>)
              .toList()
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (code != null) 'code': code,
    if (message != null) 'message': message,
    if (details != null) 'details': details,
  };

  /// Creates a copy with replaced values.
  Status copyWith({
    Object? code = unsetCopyWithValue,
    Object? message = unsetCopyWithValue,
    Object? details = unsetCopyWithValue,
  }) {
    return Status(
      code: code == unsetCopyWithValue ? this.code : code as int?,
      message: message == unsetCopyWithValue
          ? this.message
          : message as String?,
      details: details == unsetCopyWithValue
          ? this.details
          : details as List<Map<String, dynamic>>?,
    );
  }
}
