import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/auth/auth_token.dart';
import 'base_resource.dart';

/// Resource for managing ephemeral authentication tokens.
///
/// Ephemeral tokens allow secure, short-lived authentication for client-side
/// applications. They can be created server-side and passed to clients without
/// exposing the main API key.
///
/// Currently only compatible with Live API, but designed for potential
/// future expansion to standard API endpoints.
///
/// Example:
/// ```dart
/// // Server-side: Create an ephemeral token
/// final token = await client.authTokens.create(
///   authToken: AuthToken(
///     expireTime: DateTime.now().add(Duration(minutes: 30)),
///     newSessionExpireTime: DateTime.now().add(Duration(seconds: 60)),
///     uses: 1,
///   ),
/// );
///
/// // Send token.name to client application...
/// print('Token: ${token.name}');
/// ```
///
/// See also:
/// - [AuthToken] for token configuration options
/// - [EphemeralTokenProvider] for using tokens in client applications
class AuthTokensResource extends ResourceBase {
  /// Creates an [AuthTokensResource].
  AuthTokensResource({
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Creates an ephemeral authentication token.
  ///
  /// The [authToken] parameter specifies the token configuration including:
  /// - [AuthToken.expireTime]: When messages using this token expire
  /// - [AuthToken.newSessionExpireTime]: Window to start new sessions
  /// - [AuthToken.uses]: Number of times the token can be used
  /// - [AuthToken.bidiGenerateContentSetup]: Optional pre-configured setup
  ///
  /// Returns an [AuthToken] with the generated token string in [AuthToken.name].
  ///
  /// Example:
  /// ```dart
  /// final token = await client.authTokens.create(
  ///   authToken: AuthToken(
  ///     expireTime: DateTime.now().add(Duration(minutes: 30)),
  ///     uses: 1,
  ///   ),
  /// );
  ///
  /// // Use token.name for client-side authentication
  /// ```
  Future<AuthToken> create({required AuthToken authToken}) async {
    final url = requestBuilder.buildUrl('/{version}/authTokens:create');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode({'authToken': authToken.toJson()});

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return AuthToken.fromJson(responseBody);
  }
}
