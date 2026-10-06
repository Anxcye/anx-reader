import 'package:meta/meta.dart';

import '../live/messages/client/client_message.dart';

/// Ephemeral authentication token for secure client-side API access.
///
/// Ephemeral tokens provide short-lived, restricted access to the API,
/// making them suitable for client-side applications where exposing
/// the full API key would be a security risk.
///
/// Currently only compatible with Live API, but designed for potential
/// future expansion to standard API endpoints.
///
/// Example:
/// ```dart
/// // Server-side: Create ephemeral token
/// final token = await client.authTokens.create(
///   authToken: AuthToken(
///     expireTime: DateTime.now().add(Duration(minutes: 30)),
///     uses: 1,
///   ),
/// );
///
/// // Send token.name to client...
/// ```
@immutable
class AuthToken {
  /// The token string (output only from API).
  ///
  /// This is the value to send to client applications and use
  /// as the `accessToken` when connecting to the Live API.
  final String? name;

  /// When messages using this token expire.
  ///
  /// After this time, no new messages can be sent using this token.
  /// Default: 30 minutes from creation.
  /// Maximum: 20 hours from creation.
  final DateTime? expireTime;

  /// Window to start new sessions with this token.
  ///
  /// After this time, new sessions cannot be started, but existing
  /// sessions can continue until [expireTime].
  /// Default: 60 seconds from creation.
  /// Maximum: 20 hours from creation.
  final DateTime? newSessionExpireTime;

  /// Usage limit for this token.
  ///
  /// The number of times this token can be used to start a session.
  /// A value of 0 means unlimited uses.
  /// Default: 1.
  final int? uses;

  /// Optional pre-configured Live API setup.
  ///
  /// When provided, the token is locked to this specific configuration.
  /// This can be used to restrict what models and features the client
  /// can access, providing an additional layer of security.
  final BidiGenerateContentSetup? bidiGenerateContentSetup;

  /// Creates an [AuthToken] with the specified configuration.
  const AuthToken({
    this.name,
    this.expireTime,
    this.newSessionExpireTime,
    this.uses,
    this.bidiGenerateContentSetup,
  });

  /// Creates an AuthToken from JSON.
  factory AuthToken.fromJson(Map<String, dynamic> json) {
    return AuthToken(
      name: json['name'] as String?,
      expireTime: json['expireTime'] != null
          ? DateTime.parse(json['expireTime'] as String)
          : null,
      newSessionExpireTime: json['newSessionExpireTime'] != null
          ? DateTime.parse(json['newSessionExpireTime'] as String)
          : null,
      uses: json['uses'] as int?,
      bidiGenerateContentSetup: json['bidiGenerateContentSetup'] != null
          ? BidiGenerateContentSetup.fromJson(
              json['bidiGenerateContentSetup'] as Map<String, dynamic>,
            )
          : null,
    );
  }

  /// Converts this AuthToken to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      if (name != null) 'name': name,
      if (expireTime != null)
        'expireTime': expireTime!.toUtc().toIso8601String(),
      if (newSessionExpireTime != null)
        'newSessionExpireTime': newSessionExpireTime!.toUtc().toIso8601String(),
      if (uses != null) 'uses': uses,
      if (bidiGenerateContentSetup != null)
        'bidiGenerateContentSetup': bidiGenerateContentSetup!.toJson()['setup'],
    };
  }

  /// Creates a copy of this AuthToken with the given fields replaced.
  AuthToken copyWith({
    String? name,
    DateTime? expireTime,
    DateTime? newSessionExpireTime,
    int? uses,
    BidiGenerateContentSetup? bidiGenerateContentSetup,
  }) {
    return AuthToken(
      name: name ?? this.name,
      expireTime: expireTime ?? this.expireTime,
      newSessionExpireTime: newSessionExpireTime ?? this.newSessionExpireTime,
      uses: uses ?? this.uses,
      bidiGenerateContentSetup:
          bidiGenerateContentSetup ?? this.bidiGenerateContentSetup,
    );
  }

  /// Check if token is still valid for sending messages.
  ///
  /// Returns `true` if [expireTime] is null or in the future.
  bool get isValid =>
      expireTime == null || DateTime.now().toUtc().isBefore(expireTime!);

  /// Check if new sessions can still be started with this token.
  ///
  /// Returns `true` if [newSessionExpireTime] is null or in the future.
  bool get canStartNewSession =>
      newSessionExpireTime == null ||
      DateTime.now().toUtc().isBefore(newSessionExpireTime!);

  @override
  String toString() {
    // Mask the token name for security
    final maskedName = name != null
        ? '${name!.substring(0, name!.length > 8 ? 8 : name!.length)}...'
        : 'null';
    return 'AuthToken('
        'name: $maskedName, '
        'expireTime: $expireTime, '
        'newSessionExpireTime: $newSessionExpireTime, '
        'uses: $uses, '
        'bidiGenerateContentSetup: ${bidiGenerateContentSetup != null ? "..." : "null"}'
        ')';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AuthToken &&
        other.name == name &&
        other.expireTime == expireTime &&
        other.newSessionExpireTime == newSessionExpireTime &&
        other.uses == uses;
  }

  @override
  int get hashCode {
    return Object.hash(name, expireTime, newSessionExpireTime, uses);
  }
}
