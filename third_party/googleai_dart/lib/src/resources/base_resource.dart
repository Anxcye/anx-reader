import 'package:http/http.dart' as http;

import '../client/config.dart';
import '../client/interceptor_chain.dart';
import '../client/request_builder.dart';

/// Base class for all API resources.
///
/// Provides shared infrastructure (config, HTTP client, interceptors, request
/// builder) to all resource implementations. Resources delegate actual
/// HTTP execution to the interceptor chain to maintain consistent auth, retry,
/// logging, and error handling behavior.
abstract class ResourceBase {
  /// Client configuration.
  final GoogleAIConfig config;

  /// HTTP client for making requests.
  final http.Client httpClient;

  /// Interceptor chain for request/response processing.
  final InterceptorChain interceptorChain;

  /// Request builder for constructing HTTP requests.
  final RequestBuilder requestBuilder;

  /// Creates a [ResourceBase].
  ResourceBase({
    required this.config,
    required this.httpClient,
    required this.interceptorChain,
    required this.requestBuilder,
  });
}
