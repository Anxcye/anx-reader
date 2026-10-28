part of 'events.dart';

/// An error from an interaction.
class InteractionError {
  /// The error message.
  final String? message;

  /// The error code.
  final String? code;

  /// Creates an [InteractionError] instance.
  const InteractionError({this.message, this.code});

  /// Creates an [InteractionError] from JSON.
  factory InteractionError.fromJson(Map<String, dynamic> json) =>
      InteractionError(
        message: json['message'] as String?,
        code: json['code'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (message != null) 'message': message,
    if (code != null) 'code': code,
  };
}
