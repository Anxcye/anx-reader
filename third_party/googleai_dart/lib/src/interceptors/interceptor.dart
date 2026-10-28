import 'package:http/http.dart' as http;

/// Context for an HTTP request/response.
class RequestContext {
  /// HTTP request.
  final http.BaseRequest request;

  /// Optional HTTP response (set after transport).
  final http.Response? response;

  /// Request metadata.
  final Map<String, dynamic> metadata;

  /// Optional abort trigger for this request.
  final Future<void>? abortTrigger;

  /// Creates a [RequestContext].
  const RequestContext({
    required this.request,
    this.response,
    this.metadata = const {},
    this.abortTrigger,
  });

  /// Creates a copy with updated values.
  RequestContext copyWith({
    http.BaseRequest? request,
    http.Response? response,
    Map<String, dynamic>? metadata,
    Future<void>? abortTrigger,
  }) {
    return RequestContext(
      request: request ?? this.request,
      response: response ?? this.response,
      metadata: metadata ?? this.metadata,
      abortTrigger: abortTrigger ?? this.abortTrigger,
    );
  }
}

/// Function signature for interceptor chain continuation.
typedef InterceptorNext =
    Future<http.Response> Function(RequestContext context);

/// Base interceptor interface for HTTP requests.
abstract interface class Interceptor {
  /// Intercepts an HTTP request/response.
  ///
  /// The [context] contains the request and metadata.
  /// The [next] function calls the next interceptor in the chain.
  ///
  /// Returns the HTTP response.
  Future<http.Response> intercept(RequestContext context, InterceptorNext next);
}
