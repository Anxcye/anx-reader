import 'dart:math';
import 'package:http/http.dart' as http;
import '../client/config.dart';
import '../errors/exceptions.dart';

/// Wraps HTTP transport execution with retry logic.
///
/// This implements exponential backoff with jitter for retrying failed requests.
/// Per spec, retry wraps the transport layer, not part of the interceptor chain.
class RetryWrapper {
  /// Configuration containing retry policy.
  final GoogleAIConfig config;

  /// Random number generator for jitter.
  final Random _random;

  /// Creates a [RetryWrapper].
  RetryWrapper({required this.config}) : _random = Random();

  /// Executes an HTTP request with retry logic.
  ///
  /// The [execute] function should perform the actual HTTP transport.
  /// The optional [abortTrigger] allows immediate abort during retry delays.
  /// The [correlationId] is used for request tracing and error reporting.
  /// Retries are attempted for rate limits, 5xx errors, and timeouts.
  /// Only idempotent HTTP methods are retried by default.
  Future<http.Response> executeWithRetry(
    http.BaseRequest request,
    Future<http.Response> Function() execute,
    Future<void>? abortTrigger,
    String correlationId,
  ) async {
    var attempt = 0;
    Duration delay = config.retryPolicy.initialDelay;

    while (attempt <= config.retryPolicy.maxRetries) {
      try {
        final response = await execute();
        return response;
      } on AbortedException {
        // Don't retry after abort - propagate immediately
        rethrow;
      } on RateLimitException catch (e) {
        // Handle rate limiting specially
        if (attempt >= config.retryPolicy.maxRetries) {
          rethrow;
        }

        // Honor retryAfter from server if provided
        if (e.retryAfter != null) {
          final serverDelay = e.retryAfter!.difference(DateTime.now());
          // Use server's suggested delay if it's reasonable (< maxDelay * 2)
          if (serverDelay.inMilliseconds > 0 &&
              serverDelay <= config.retryPolicy.maxDelay * 2) {
            delay = serverDelay;
          }
        }

        await _delayWithAbortCheck(delay, abortTrigger, correlationId);
        attempt++;
        delay = _exponentialBackoff(delay);
      } on ApiException catch (e) {
        // Retry on 5xx server errors (transient failures)
        if (e.code >= 500 && e.code < 600) {
          // Check if method is idempotent before retrying
          if (!_isIdempotent(request.method)) {
            rethrow; // Don't retry non-idempotent operations
          }

          if (attempt >= config.retryPolicy.maxRetries) {
            rethrow;
          }

          await _delayWithAbortCheck(delay, abortTrigger, correlationId);
          attempt++;
          delay = _exponentialBackoff(delay);
        } else {
          // 4xx errors are client errors, don't retry
          rethrow;
        }
      } on TimeoutException {
        // Retry on timeout for idempotent methods only
        if (!_isIdempotent(request.method)) {
          rethrow;
        }

        if (attempt >= config.retryPolicy.maxRetries) {
          rethrow;
        }

        await _delayWithAbortCheck(delay, abortTrigger, correlationId);
        attempt++;
        delay = _exponentialBackoff(delay);
      }
    }

    // Should never reach here, but throw if we somehow do
    throw ApiException(
      code: 0,
      message: 'Max retries (${config.retryPolicy.maxRetries}) exceeded',
    );
  }

  /// Checks if an HTTP method is idempotent and safe to retry.
  ///
  /// Per spec: "Retry decisions should consider HTTP method idempotency"
  /// Safe methods: GET, HEAD, OPTIONS, PUT, DELETE
  /// Unsafe: POST, PATCH (may create duplicates)
  bool _isIdempotent(String method) {
    const idempotentMethods = {'GET', 'HEAD', 'OPTIONS', 'PUT', 'DELETE'};
    return idempotentMethods.contains(method.toUpperCase());
  }

  /// Applies exponential backoff to the current delay.
  Duration _exponentialBackoff(Duration currentDelay) {
    final nextDelay = currentDelay * 2;
    return nextDelay > config.retryPolicy.maxDelay
        ? config.retryPolicy.maxDelay
        : nextDelay;
  }

  /// Delays with jitter to avoid thundering herd.
  Future<void> _delayWithJitter(Duration delay) async {
    final jitterMs =
        (_random.nextDouble() *
                config.retryPolicy.jitter *
                delay.inMilliseconds)
            .round();

    final finalDelay = delay + Duration(milliseconds: jitterMs);
    await Future<void>.delayed(finalDelay);
  }

  /// Delays with abort check - aborts immediately if trigger fires during delay.
  ///
  /// This allows immediate abort during retry delays instead of waiting
  /// for the full delay duration. If no abort trigger is provided,
  /// falls back to normal jittered delay.
  Future<void> _delayWithAbortCheck(
    Duration delay,
    Future<void>? abortTrigger,
    String correlationId,
  ) async {
    if (abortTrigger == null) {
      // No abort trigger, use normal delay
      await _delayWithJitter(delay);
    } else {
      // Race the delay with abort trigger
      final jitterMs =
          (_random.nextDouble() *
                  config.retryPolicy.jitter *
                  delay.inMilliseconds)
              .round();

      final finalDelay = delay + Duration(milliseconds: jitterMs);

      await Future.any([
        Future<void>.delayed(finalDelay),
        abortTrigger.then((_) {
          throw AbortedException(
            message: 'Request aborted during retry delay',
            correlationId: correlationId,
            timestamp: DateTime.now(),
            stage: AbortionStage.beforeRequest, // Before next retry attempt
          );
        }),
      ]);
    }
  }
}
