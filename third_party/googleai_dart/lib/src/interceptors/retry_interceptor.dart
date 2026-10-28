import 'dart:math';
import 'package:http/http.dart' as http;
import '../client/config.dart';
import '../errors/exceptions.dart';
import 'interceptor.dart';

/// Interceptor that retries failed requests with exponential backoff.
class RetryInterceptor implements Interceptor {
  /// Configuration containing retry policy.
  final GoogleAIConfig config;

  /// Random number generator for jitter.
  final Random _random;

  /// Creates a [RetryInterceptor].
  RetryInterceptor({required this.config}) : _random = Random();

  @override
  Future<http.Response> intercept(
    RequestContext context,
    InterceptorNext next,
  ) async {
    var attempt = 0;
    Duration delay = config.retryPolicy.initialDelay;

    while (attempt <= config.retryPolicy.maxRetries) {
      try {
        // Update context with attempt counter
        final updatedContext = context.copyWith(
          metadata: {
            ...context.metadata,
            'attemptNumber': attempt,
            'retryCount': attempt, // For logging
          },
        );

        final response = await next(updatedContext);
        return response;
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

        await _delayWithJitter(delay);
        attempt++;
        delay = _exponentialBackoff(delay);
      } on ApiException catch (e) {
        // Retry on 5xx server errors (transient failures)
        if (e.code >= 500 && e.code < 600) {
          if (attempt >= config.retryPolicy.maxRetries) {
            rethrow;
          }

          await _delayWithJitter(delay);
          attempt++;
          delay = _exponentialBackoff(delay);
        } else {
          // 4xx errors are client errors, don't retry
          rethrow;
        }
      } on TimeoutException {
        // Retry on timeout
        if (attempt >= config.retryPolicy.maxRetries) {
          rethrow;
        }

        await _delayWithJitter(delay);
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
}
