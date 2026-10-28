import 'package:googleai_dart/googleai_dart.dart' as g;
import 'package:googleapis_auth/auth_io.dart' as auth;
import 'package:http/http.dart' as http;

/// {@template http_client_auth_provider}
/// Authentication provider that bridges googleapis_auth with googleai_dart.
///
/// This provider wraps Google Cloud service account credentials and manages
/// OAuth token refresh automatically, making it suitable for long-running
/// Vertex AI applications.
///
/// Example:
/// ```dart
/// final authProvider = HttpClientAuthProvider(
///   credentials: ServiceAccountCredentials.fromJson({...}),
///   scopes: ['https://www.googleapis.com/auth/cloud-platform'],
/// );
///
/// final chat = ChatVertexAI(
///   authProvider: authProvider,
///   project: 'my-project',
/// );
/// ```
///
/// The provider automatically refreshes tokens when they expire.
/// {@endtemplate}
class HttpClientAuthProvider implements g.AuthProvider {
  /// {@macro http_client_auth_provider}
  HttpClientAuthProvider({
    required auth.ServiceAccountCredentials credentials,
    required List<String> scopes,
    http.Client? httpClient,
  }) : _credentials = credentials,
       _scopes = scopes,
       _httpClient = httpClient ?? http.Client();

  /// Creates an auth provider from a JSON service account key.
  ///
  /// Example:
  /// ```dart
  /// final authProvider = HttpClientAuthProvider.fromJson(
  ///   serviceAccountJson: {
  ///     "type": "service_account",
  ///     "project_id": "your-project",
  ///     // ... rest of service account JSON
  ///   },
  ///   scopes: ['https://www.googleapis.com/auth/cloud-platform'],
  /// );
  /// ```
  factory HttpClientAuthProvider.fromJson({
    required Map<String, dynamic> serviceAccountJson,
    required List<String> scopes,
    http.Client? httpClient,
  }) {
    return HttpClientAuthProvider(
      credentials: auth.ServiceAccountCredentials.fromJson(serviceAccountJson),
      scopes: scopes,
      httpClient: httpClient,
    );
  }

  final auth.ServiceAccountCredentials _credentials;
  final List<String> _scopes;
  final http.Client _httpClient;
  auth.AccessCredentials? _cachedCredentials;

  @override
  Future<g.AuthCredentials> getCredentials() async {
    // Refresh if expired or not yet obtained
    if (_cachedCredentials == null ||
        _cachedCredentials!.accessToken.expiry.isBefore(DateTime.now())) {
      _cachedCredentials = await auth.obtainAccessCredentialsViaServiceAccount(
        _credentials,
        _scopes,
        _httpClient,
      );
    }

    return g.BearerTokenCredentials(_cachedCredentials!.accessToken.data);
  }

  /// Closes the HTTP client and cleans up resources.
  ///
  /// Call this method when you're done using the auth provider to prevent
  /// resource leaks.
  void close() {
    _httpClient.close();
  }
}
