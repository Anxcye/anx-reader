import 'package:logging/logging.dart';
import '../auth/auth_provider.dart';

/// API version for the GoogleAI and Vertex AI APIs.
/// https://ai.google.dev/gemini-api/docs/api-versions
enum ApiVersion {
  /// Stable version (v1) - Production-ready with guaranteed stability.
  v1('v1'),

  /// Beta version (v1beta) - Early-access features, subject to breaking changes.
  v1beta('v1beta');

  /// The version string used in API URLs.
  final String value;

  const ApiVersion(this.value);
}

/// API mode determining which Google AI service to use.
enum ApiMode {
  /// Google AI (Gemini Developer API) - Uses generativelanguage.googleapis.com
  googleAI,

  /// Vertex AI - Uses {location}-aiplatform.googleapis.com with GCP project
  vertexAI,
}

/// Retry policy configuration.
class RetryPolicy {
  /// Maximum number of retry attempts.
  final int maxRetries;

  /// Initial delay before first retry.
  final Duration initialDelay;

  /// Maximum delay between retries.
  final Duration maxDelay;

  /// Jitter factor (0.0 - 1.0).
  final double jitter;

  /// Creates a [RetryPolicy].
  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.maxDelay = const Duration(seconds: 60),
    this.jitter = 0.1,
  });

  /// Default retry policy (3 retries, 1s initial delay).
  static const defaultPolicy = RetryPolicy();
}

/// Configuration for the GoogleAI client.
class GoogleAIConfig {
  /// Base URL for the API.
  final String baseUrl;

  /// API mode (Google AI or Vertex AI).
  final ApiMode apiMode;

  /// API version (v1 or v1beta).
  final ApiVersion apiVersion;

  /// GCP project ID (required for Vertex AI).
  final String? projectId;

  /// GCP location/region (required for Vertex AI, e.g., 'us-central1', 'global').
  final String? location;

  /// Authentication provider for dynamic credential retrieval.
  ///
  /// This provider is called on each request attempt (including retries),
  /// allowing OAuth implementations to refresh expired tokens automatically.
  ///
  /// Example with API key:
  /// ```dart
  /// GoogleAIConfig(
  ///   authProvider: ApiKeyProvider('YOUR_API_KEY'),
  /// )
  /// ```
  ///
  /// Example with OAuth:
  /// ```dart
  /// GoogleAIConfig(
  ///   authProvider: MyOAuthProvider(),
  /// )
  /// ```
  final AuthProvider? authProvider;

  /// Default headers to include in all requests.
  final Map<String, String> defaultHeaders;

  /// Default query parameters to include in all requests.
  final Map<String, String> defaultQueryParams;

  /// Request timeout.
  final Duration timeout;

  /// Retry policy.
  final RetryPolicy retryPolicy;

  /// Log level.
  final Level logLevel;

  /// Fields to redact in logs (case-insensitive).
  final List<String> redactionList;

  /// Creates a [GoogleAIConfig].
  const GoogleAIConfig({
    this.baseUrl = 'https://generativelanguage.googleapis.com',
    this.apiMode = ApiMode.googleAI,
    this.apiVersion = ApiVersion.v1beta,
    this.projectId,
    this.location,
    this.authProvider,
    this.defaultHeaders = const {},
    this.defaultQueryParams = const {},
    this.timeout = const Duration(minutes: 2),
    this.retryPolicy = RetryPolicy.defaultPolicy,
    this.logLevel = Level.INFO,
    this.redactionList = const [
      'authorization',
      'api-key',
      'api_key',
      'x-goog-api-key',
      'token',
      'password',
      'secret',
      'bearer',
    ],
  });

  /// Creates a config for Google AI (Gemini Developer API).
  ///
  /// Example:
  /// ```dart
  /// final config = GoogleAIConfig.googleAI(
  ///   apiVersion: ApiVersion.v1, // Stable version
  ///   authProvider: ApiKeyProvider('YOUR_API_KEY'),
  /// );
  /// ```
  const GoogleAIConfig.googleAI({
    ApiVersion apiVersion = ApiVersion.v1beta,
    required AuthProvider authProvider,
    Map<String, String> defaultHeaders = const {},
    Map<String, String> defaultQueryParams = const {},
    Duration timeout = const Duration(minutes: 2),
    RetryPolicy retryPolicy = RetryPolicy.defaultPolicy,
    Level logLevel = Level.INFO,
    List<String> redactionList = const [
      'authorization',
      'api-key',
      'api_key',
      'x-goog-api-key',
      'token',
      'password',
      'secret',
      'bearer',
    ],
  }) : this(
         baseUrl: 'https://generativelanguage.googleapis.com',
         apiMode: ApiMode.googleAI,
         apiVersion: apiVersion,
         authProvider: authProvider,
         defaultHeaders: defaultHeaders,
         defaultQueryParams: defaultQueryParams,
         timeout: timeout,
         retryPolicy: retryPolicy,
         logLevel: logLevel,
         redactionList: redactionList,
       );

  /// Creates a config for Vertex AI.
  ///
  /// Requires [projectId] and [location] for GCP integration.
  /// Authentication must use OAuth 2.0 with service account credentials.
  ///
  /// Example:
  /// ```dart
  /// final config = GoogleAIConfig.vertexAI(
  ///   projectId: 'your-project-id',
  ///   location: 'us-central1',
  ///   apiVersion: ApiVersion.v1, // Stable version
  ///   authProvider: MyOAuthProvider(),
  /// );
  /// ```
  GoogleAIConfig.vertexAI({
    required String projectId,
    String location = 'us-central1',
    ApiVersion apiVersion = ApiVersion.v1,
    required AuthProvider authProvider,
    Map<String, String> defaultHeaders = const {},
    Map<String, String> defaultQueryParams = const {},
    Duration timeout = const Duration(minutes: 2),
    RetryPolicy retryPolicy = RetryPolicy.defaultPolicy,
    Level logLevel = Level.INFO,
    List<String> redactionList = const [
      'authorization',
      'api-key',
      'api_key',
      'x-goog-api-key',
      'token',
      'password',
      'secret',
      'bearer',
    ],
  }) : this(
         baseUrl: 'https://$location-aiplatform.googleapis.com',
         apiMode: ApiMode.vertexAI,
         apiVersion: apiVersion,
         projectId: projectId,
         location: location,
         authProvider: authProvider,
         defaultHeaders: defaultHeaders,
         defaultQueryParams: defaultQueryParams,
         timeout: timeout,
         retryPolicy: retryPolicy,
         logLevel: logLevel,
         redactionList: redactionList,
       );

  /// Creates a copy with overridden values.
  GoogleAIConfig copyWith({
    String? baseUrl,
    ApiMode? apiMode,
    ApiVersion? apiVersion,
    String? projectId,
    String? location,
    AuthProvider? authProvider,
    Map<String, String>? defaultHeaders,
    Map<String, String>? defaultQueryParams,
    Duration? timeout,
    RetryPolicy? retryPolicy,
    Level? logLevel,
    List<String>? redactionList,
  }) {
    return GoogleAIConfig(
      baseUrl: baseUrl ?? this.baseUrl,
      apiMode: apiMode ?? this.apiMode,
      apiVersion: apiVersion ?? this.apiVersion,
      projectId: projectId ?? this.projectId,
      location: location ?? this.location,
      authProvider: authProvider ?? this.authProvider,
      defaultHeaders: defaultHeaders ?? this.defaultHeaders,
      defaultQueryParams: defaultQueryParams ?? this.defaultQueryParams,
      timeout: timeout ?? this.timeout,
      retryPolicy: retryPolicy ?? this.retryPolicy,
      logLevel: logLevel ?? this.logLevel,
      redactionList: redactionList ?? this.redactionList,
    );
  }
}
