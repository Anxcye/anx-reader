import 'dart:async';

import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';
import '../interceptors/interceptor.dart';
import '../utils/request_id.dart';
import 'retry_wrapper.dart';

/// Builds and executes an interceptor chain.
class InterceptorChain {
  /// List of interceptors to execute in order.
  final List<Interceptor> interceptors;

  /// HTTP client for transport layer.
  final http.Client httpClient;

  /// Retry wrapper for transport execution.
  final RetryWrapper? retryWrapper;

  /// Creates an [InterceptorChain].
  const InterceptorChain({
    required this.interceptors,
    required this.httpClient,
    this.retryWrapper,
  });

  /// Executes the interceptor chain for a request.
  ///
  /// The optional [abortTrigger] allows canceling the request before completion.
  ///
  /// Returns the HTTP response after all interceptors have processed it.
  Future<http.Response> execute(
    http.BaseRequest request, {
    Future<void>? abortTrigger,
  }) {
    final context = RequestContext(
      request: request,
      metadata: {},
      abortTrigger: abortTrigger,
    );

    return _buildChain(0)(context);
  }

  /// Builds the interceptor chain recursively.
  InterceptorNext _buildChain(int index) {
    if (index >= interceptors.length) {
      // Terminal: execute the actual HTTP request
      // Per spec, retry wraps the transport execution
      return (context) {
        final requestToSend = context.request;

        // Transport execution function
        Future<http.Response> executeTransport() async {
          if (context.abortTrigger != null) {
            // Wrap request to enable http client's native abort support
            final abortableRequest = _AbortableRequestWrapper(
              requestToSend,
              context.abortTrigger,
            );

            // Track stage for accurate abort reporting
            var stage = AbortionStage.beforeRequest;

            try {
              final streamedResponse = await httpClient.send(abortableRequest);
              // If we get here, request was sent successfully
              stage = AbortionStage.duringResponse;
              return await http.Response.fromStream(streamedResponse);
            } on http.RequestAbortedException catch (e) {
              // Convert http package's abort exception to our AbortedException
              final correlationId =
                  context.metadata['correlationId'] as String? ??
                  context.request.headers['X-Request-ID'] ??
                  generateRequestId();
              throw AbortedException(
                message: 'Request aborted by user',
                correlationId: correlationId,
                timestamp: DateTime.now(),
                stage: stage,
                reason: e,
              );
            }
          } else {
            // No abort trigger - normal execution
            final streamedResponse = await httpClient.send(requestToSend);
            return http.Response.fromStream(streamedResponse);
          }
        }

        // Execute with or without retry wrapper
        if (retryWrapper != null) {
          // Extract correlation ID for retry wrapper tracing
          final correlationId =
              context.metadata['correlationId'] as String? ??
              context.request.headers['X-Request-ID'] ??
              generateRequestId();

          // Per spec: Retry wraps transport execution
          return retryWrapper!.executeWithRetry(
            requestToSend,
            executeTransport,
            context
                .abortTrigger, // Pass abort trigger for retry delay interruption
            correlationId, // Pass correlation ID for error tracing
          );
        } else {
          return executeTransport();
        }
      };
    }

    // Recursive: call current interceptor with next in chain
    return (context) {
      final interceptor = interceptors[index];
      final next = _buildChain(index + 1);

      return interceptor.intercept(context, next);
    };
  }
}

/// Wrapper to make a BaseRequest abortable by implementing Abortable mixin.
///
/// This allows the http client (IOClient/BrowserClient) to properly cancel
/// the HTTP connection when the abort trigger completes, preventing resource
/// leaks and background network activity.
class _AbortableRequestWrapper extends http.BaseRequest
    implements http.Abortable {
  final http.BaseRequest _inner;

  @override
  final Future<void>? abortTrigger;

  _AbortableRequestWrapper(this._inner, this.abortTrigger)
    : super(_inner.method, _inner.url) {
    headers.addAll(_inner.headers);
    followRedirects = _inner.followRedirects;
    maxRedirects = _inner.maxRedirects;
    persistentConnection = _inner.persistentConnection;
  }

  @override
  http.ByteStream finalize() {
    super.finalize();
    return _inner.finalize();
  }
}
