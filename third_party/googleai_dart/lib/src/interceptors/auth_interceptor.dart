import 'package:http/http.dart' as http;
import '../auth/auth_provider.dart';
import '../client/config.dart';
import 'interceptor.dart';

/// Interceptor that adds authentication to requests.
///
/// This interceptor implements the auth layer of the configuration precedence:
/// Global → Auth → Endpoint → Request (highest).
///
/// Important: Auth headers/params are ONLY added if not already present,
/// ensuring that request-level auth always takes precedence.
/// This preserves the last-write-wins semantics of the spec.
///
/// The interceptor calls [AuthProvider.getCredentials] on each request
/// (including retries), enabling OAuth implementations to refresh expired
/// tokens automatically.
class AuthInterceptor implements Interceptor {
  /// Configuration containing auth provider.
  final GoogleAIConfig config;

  /// Creates an [AuthInterceptor].
  const AuthInterceptor({required this.config});

  @override
  Future<http.Response> intercept(
    RequestContext context,
    InterceptorNext next,
  ) async {
    final request = context.request;

    // Get credentials from auth provider (called on each request/retry)
    var authenticatedRequest = request;

    if (config.authProvider != null) {
      final credentials = await config.authProvider!.getCredentials();
      authenticatedRequest = _applyCredentials(request, credentials);
    }

    final newContext = context.copyWith(request: authenticatedRequest);
    return next(newContext);
  }

  /// Applies authentication credentials to request.
  http.BaseRequest _applyCredentials(
    http.BaseRequest request,
    AuthCredentials credentials,
  ) {
    return switch (credentials) {
      ApiKeyCredentials(:final apiKey, :final placement) => _addApiKey(
        request,
        apiKey,
        placement,
      ),
      BearerTokenCredentials(:final token) => _addBearerToken(request, token),
      EphemeralTokenCredentials(:final token, :final placement) =>
        _addEphemeralToken(request, token, placement),
      NoAuthCredentials() => request,
    };
  }

  /// Adds API key to request based on placement strategy.
  http.BaseRequest _addApiKey(
    http.BaseRequest request,
    String apiKey,
    AuthPlacement placement,
  ) {
    if (placement == AuthPlacement.header) {
      // Add as header (only if not already present)
      if (request is http.Request) {
        // Don't overwrite existing X-Goog-Api-Key header
        if (request.headers.containsKey('X-Goog-Api-Key')) {
          return request;
        }
        return http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..headers['X-Goog-Api-Key'] = apiKey
          ..bodyBytes = request.bodyBytes
          ..encoding = request.encoding;
      }
    } else {
      // Add as query parameter (default)
      final uri = request.url;
      final queryParams = Map<String, dynamic>.from(uri.queryParameters);

      // Don't overwrite existing 'key' query parameter
      if (queryParams.containsKey('key')) {
        return request;
      }
      queryParams['key'] = apiKey;

      final newUri = uri.replace(queryParameters: queryParams);

      if (request is http.Request) {
        return http.Request(request.method, newUri)
          ..headers.addAll(request.headers)
          ..bodyBytes = request.bodyBytes
          ..encoding = request.encoding;
      }
    }

    return request;
  }

  /// Adds Bearer token to request headers.
  http.BaseRequest _addBearerToken(
    http.BaseRequest request,
    String bearerToken,
  ) {
    if (request is http.Request) {
      // Don't overwrite existing Authorization header
      if (request.headers.containsKey('Authorization')) {
        return request;
      }
      return http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..headers['Authorization'] = 'Bearer $bearerToken'
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;
    }

    return request;
  }

  /// Adds ephemeral token to request based on placement strategy.
  http.BaseRequest _addEphemeralToken(
    http.BaseRequest request,
    String token,
    EphemeralTokenPlacement placement,
  ) {
    if (placement == EphemeralTokenPlacement.header) {
      // Add as header
      if (request is http.Request) {
        // Don't overwrite existing Authorization header
        if (request.headers.containsKey('Authorization')) {
          return request;
        }
        return http.Request(request.method, request.url)
          ..headers.addAll(request.headers)
          ..headers['Authorization'] = 'Token $token'
          ..bodyBytes = request.bodyBytes
          ..encoding = request.encoding;
      }
    } else {
      // Add as query parameter (default)
      final uri = request.url;
      final queryParams = Map<String, dynamic>.from(uri.queryParameters);

      // Don't overwrite existing 'access_token' query parameter
      if (queryParams.containsKey('access_token')) {
        return request;
      }
      queryParams['access_token'] = token;

      final newUri = uri.replace(queryParameters: queryParams);

      if (request is http.Request) {
        return http.Request(request.method, newUri)
          ..headers.addAll(request.headers)
          ..bodyBytes = request.bodyBytes
          ..encoding = request.encoding;
      }
    }

    return request;
  }
}
