import 'config.dart';
import 'endpoint_config.dart';

/// Builds API request URLs and headers with proper precedence.
///
/// Implements last-write-wins merge per spec:
/// - Headers: Global → Endpoint → Request (highest)
///   Note: Auth headers are added by AuthInterceptor ONLY if not present,
///   ensuring request-level headers always win.
/// - Query Params: Global → Endpoint → Request (highest)
///   Note: Auth query params (e.g., 'key') are added by AuthInterceptor
///   ONLY if not present, ensuring request-level params always win.
class RequestBuilder {
  /// Configuration.
  final GoogleAIConfig config;

  /// Creates a [RequestBuilder].
  const RequestBuilder({required this.config});

  /// Builds a URL for an API endpoint.
  ///
  /// Merges query parameters in order: Global → Endpoint → Request.
  /// Later values override earlier ones (last-write-wins).
  ///
  /// Transforms the path based on the API mode and version.
  /// Use `{version}` placeholder in paths, which gets replaced with the configured version.
  /// - For Google AI: `/{version}/models/{model}:generateContent`
  /// - For Vertex AI: `/{version}/projects/{projectId}/locations/{location}/publishers/google/models/{model}:generateContent`
  Uri buildUrl(
    String path, {
    EndpointConfig? endpointConfig,
    Map<String, dynamic>? queryParams,
  }) {
    final transformedPath = _transformPath(path);
    final uri = Uri.parse('${config.baseUrl}$transformedPath');
    final mergedParams = <String, dynamic>{
      ...config.defaultQueryParams,
      ...?endpointConfig?.queryParams,
      ...?queryParams,
    };

    return uri.replace(queryParameters: mergedParams);
  }

  /// Transforms the path based on API mode and version.
  ///
  /// Replaces `{version}` placeholder with the configured version,
  /// and for Vertex AI, injects project/location path segments.
  String _transformPath(String path) {
    // Replace {version} placeholder with configured version
    var transformedPath = path.replaceFirst(
      '{version}',
      config.apiVersion.value,
    );

    // For Vertex AI, transform the path to include project and location
    if (config.apiMode == ApiMode.vertexAI) {
      // Pattern: /{version}/models/{model}:action
      // Becomes: /{version}/projects/{projectId}/locations/{location}/publishers/google/models/{model}:action
      final versionPattern = '/${config.apiVersion.value}/';

      if (transformedPath.startsWith(versionPattern)) {
        final afterVersion = transformedPath.substring(versionPattern.length);

        // Insert project/location path
        transformedPath =
            '$versionPattern'
            'projects/${config.projectId}/'
            'locations/${config.location}/'
            'publishers/google/$afterVersion';
      }
    }

    return transformedPath;
  }

  /// Builds headers for a request.
  ///
  /// Merges headers in order: Global → Endpoint → Request.
  /// Later values override earlier ones (last-write-wins).
  /// Note: Auth interceptor runs separately and adds auth headers.
  Map<String, String> buildHeaders({
    EndpointConfig? endpointConfig,
    Map<String, String>? additionalHeaders,
  }) {
    return {
      ...config.defaultHeaders,
      ...?endpointConfig?.headers,
      ...?additionalHeaders,
    };
  }
}
