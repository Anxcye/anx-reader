/// Authentication provider interface for the GoogleAI client.
///
/// This interface allows for dynamic authentication credential retrieval,
/// enabling OAuth token refresh during retry attempts.
///
/// The [getCredentials] method is called on each request attempt, allowing
/// implementations to refresh expired tokens automatically.
abstract interface class AuthProvider {
  /// Retrieves authentication credentials.
  ///
  /// This method is called on each request attempt (including retries),
  /// allowing implementations to provide fresh tokens when needed.
  ///
  /// Implementations should:
  /// - Return cached credentials if still valid
  /// - Refresh and return new credentials if expired
  /// - Handle refresh failures gracefully
  Future<AuthCredentials> getCredentials();
}

/// Authentication credentials returned by [AuthProvider].
sealed class AuthCredentials {
  /// Creates an [AuthCredentials].
  const AuthCredentials();
}

/// API key authentication credentials.
class ApiKeyCredentials extends AuthCredentials {
  /// The API key to use for authentication.
  final String apiKey;

  /// Where to place the API key (query param or header).
  final AuthPlacement placement;

  /// Creates [ApiKeyCredentials].
  const ApiKeyCredentials(
    this.apiKey, {
    this.placement = AuthPlacement.queryParam,
  });
}

/// Bearer token authentication credentials.
class BearerTokenCredentials extends AuthCredentials {
  /// The bearer token to use for authentication.
  final String token;

  /// Creates [BearerTokenCredentials].
  const BearerTokenCredentials(this.token);
}

/// No authentication credentials.
class NoAuthCredentials extends AuthCredentials {
  /// Creates [NoAuthCredentials].
  const NoAuthCredentials();
}

/// Ephemeral token authentication credentials.
///
/// Used for short-lived, secure client-side authentication.
/// Ephemeral tokens can be placed as query parameters or in headers.
///
/// See also:
/// - [AuthToken] for creating ephemeral tokens
/// - [EphemeralTokenProvider] for using ephemeral tokens
class EphemeralTokenCredentials extends AuthCredentials {
  /// The ephemeral token string.
  final String token;

  /// Where to place the token (query param or header).
  final EphemeralTokenPlacement placement;

  /// Creates [EphemeralTokenCredentials].
  const EphemeralTokenCredentials(
    this.token, {
    this.placement = EphemeralTokenPlacement.queryParam,
  });
}

/// Ephemeral token placement strategy.
enum EphemeralTokenPlacement {
  /// Add as query parameter (?access_token=...)
  queryParam,

  /// Add as header (Authorization: Token ...)
  header,
}

/// Authentication placement strategy.
enum AuthPlacement {
  /// Add API key as query parameter (?key=...)
  queryParam,

  /// Add API key as header (X-Goog-Api-Key: ...)
  header,
}

/// Simple API key provider with static credentials.
///
/// This provider returns the same API key on every call to [getCredentials].
/// It's suitable for use cases where the API key doesn't expire.
///
/// Example:
/// ```dart
/// final client = GoogleAIClient(
///   config: GoogleAIConfig(
///     authProvider: ApiKeyProvider('YOUR_API_KEY'),
///   ),
/// );
/// ```
class ApiKeyProvider implements AuthProvider {
  /// The API key to use for authentication.
  final String apiKey;

  /// Where to place the API key (query param or header).
  final AuthPlacement placement;

  /// Creates an [ApiKeyProvider].
  const ApiKeyProvider(
    this.apiKey, {
    this.placement = AuthPlacement.queryParam,
  });

  @override
  Future<AuthCredentials> getCredentials() async {
    return ApiKeyCredentials(apiKey, placement: placement);
  }
}

/// Simple bearer token provider with static credentials.
///
/// This provider returns the same bearer token on every call to [getCredentials].
/// For OAuth flows with token refresh, create a custom provider that extends
/// this class or implements [AuthProvider] directly.
///
/// Example with static token:
/// ```dart
/// final client = GoogleAIClient(
///   config: GoogleAIConfig(
///     authProvider: BearerTokenProvider('YOUR_TOKEN'),
///   ),
/// );
/// ```
///
/// Example with OAuth refresh:
/// ```dart
/// class OAuthProvider implements AuthProvider {
///   String? _cachedToken;
///   DateTime? _expiresAt;
///
///   @override
///   Future<AuthCredentials> getCredentials() async {
///     // Return cached token if still valid
///     if (_cachedToken != null &&
///         _expiresAt != null &&
///         DateTime.now().isBefore(_expiresAt!)) {
///       return BearerTokenCredentials(_cachedToken!);
///     }
///
///     // Refresh token
///     final response = await refreshToken();
///     _cachedToken = response.accessToken;
///     _expiresAt = DateTime.now().add(Duration(seconds: response.expiresIn));
///
///     return BearerTokenCredentials(_cachedToken!);
///   }
/// }
/// ```
class BearerTokenProvider implements AuthProvider {
  /// The bearer token to use for authentication.
  final String token;

  /// Creates a [BearerTokenProvider].
  const BearerTokenProvider(this.token);

  @override
  Future<AuthCredentials> getCredentials() async {
    return BearerTokenCredentials(token);
  }
}

/// Provider that returns no authentication credentials.
///
/// This is useful for testing or for endpoints that don't require authentication.
///
/// Example:
/// ```dart
/// final client = GoogleAIClient(
///   config: GoogleAIConfig(
///     authProvider: NoAuthProvider(),
///   ),
/// );
/// ```
class NoAuthProvider implements AuthProvider {
  /// Creates a [NoAuthProvider].
  const NoAuthProvider();

  @override
  Future<AuthCredentials> getCredentials() async {
    return const NoAuthCredentials();
  }
}

/// Provider for ephemeral token authentication.
///
/// Ephemeral tokens are short-lived credentials that can be safely passed
/// to client-side applications. They are created server-side using the
/// [AuthTokensResource.create] method and used client-side for connecting
/// to the Live API.
///
/// Example:
/// ```dart
/// // Client receives token from server
/// final liveClient = LiveClient(config: GoogleAIConfig(
///   authProvider: EphemeralTokenProvider(tokenFromServer),
/// ));
///
/// final session = await liveClient.connect(
///   model: 'gemini-2.0-flash-live-001',
/// );
/// ```
class EphemeralTokenProvider implements AuthProvider {
  /// The ephemeral token string.
  final String token;

  /// Where to place the token (query param or header).
  final EphemeralTokenPlacement placement;

  /// Creates an [EphemeralTokenProvider].
  const EphemeralTokenProvider(
    this.token, {
    this.placement = EphemeralTokenPlacement.queryParam,
  });

  @override
  Future<AuthCredentials> getCredentials() async {
    return EphemeralTokenCredentials(token, placement: placement);
  }
}
