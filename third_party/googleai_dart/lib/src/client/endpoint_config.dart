/// Configuration for a specific API endpoint.
///
/// Provides endpoint-level defaults for headers and query parameters that sit
/// between global config and request-level overrides in the precedence chain:
/// Global → Endpoint → Request (highest).
class EndpointConfig {
  /// Default headers for this endpoint.
  final Map<String, String> headers;

  /// Default query parameters for this endpoint.
  final Map<String, String> queryParams;

  /// Creates an [EndpointConfig].
  const EndpointConfig({this.headers = const {}, this.queryParams = const {}});

  /// Empty endpoint config (no defaults).
  static const empty = EndpointConfig();
}
