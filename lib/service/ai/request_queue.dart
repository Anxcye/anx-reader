import 'dart:async';

enum RateLimitErrorType {
  unknown,
  rateLimit,
  quotaExceeded,
  serverBusy,
  timeout,
}

class AiRequestQueueManager {
  AiRequestQueueManager._();

  static final AiRequestQueueManager instance = AiRequestQueueManager._();

  Future<void> _tail = Future<void>.value();

  Future<T> enqueue<T>(FutureOr<T> Function() action) {
    final next = _tail.then(
      (_) => Future<T>.sync(action),
      onError: (_) => Future<T>.sync(action),
    );
    _tail = next.then<void>((_) {}, onError: (_, __) {});
    return next;
  }

  void clear() {
    _tail = Future<void>.value();
  }
}

RateLimitErrorType parseRateLimitError(Object error) {
  final message = error.toString().toLowerCase();

  if (message.contains('quota') ||
      message.contains('insufficient_quota') ||
      message.contains('billing')) {
    return RateLimitErrorType.quotaExceeded;
  }

  if (message.contains('429') ||
      message.contains('rate limit') ||
      message.contains('too many request')) {
    return RateLimitErrorType.rateLimit;
  }

  if (message.contains('timeout') || message.contains('timed out')) {
    return RateLimitErrorType.timeout;
  }

  if (message.contains('503') ||
      message.contains('502') ||
      message.contains('504') ||
      message.contains('server busy') ||
      message.contains('overload') ||
      message.contains('temporarily unavailable')) {
    return RateLimitErrorType.serverBusy;
  }

  return RateLimitErrorType.unknown;
}

Duration calculateRetryDelay(RateLimitErrorType type, int retryCount) {
  final attempt = retryCount < 1 ? 1 : retryCount;
  final baseSeconds = switch (type) {
    RateLimitErrorType.rateLimit => 2,
    RateLimitErrorType.quotaExceeded => 30,
    RateLimitErrorType.serverBusy => 3,
    RateLimitErrorType.timeout => 2,
    RateLimitErrorType.unknown => 1,
  };
  final seconds = baseSeconds * (1 << (attempt - 1));
  return Duration(seconds: seconds.clamp(1, 60));
}
