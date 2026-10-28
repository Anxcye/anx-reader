/// Metadata about the HTTP request that caused an error.
class RequestMetadata {
  /// HTTP method.
  final String method;

  /// Request URL.
  final Uri url;

  /// Request headers (redacted for security).
  final Map<String, String> headers;

  /// Correlation/request ID.
  final String correlationId;

  /// When the request was sent.
  final DateTime timestamp;

  /// Attempt number (for retried requests).
  final int attemptNumber;

  /// Creates [RequestMetadata].
  const RequestMetadata({
    required this.method,
    required this.url,
    required this.headers,
    required this.correlationId,
    required this.timestamp,
    this.attemptNumber = 0,
  });
}

/// Metadata about the HTTP response that caused an error.
class ResponseMetadata {
  /// HTTP status code.
  final int statusCode;

  /// Response headers.
  final Map<String, String> headers;

  /// Excerpt of response body (first 200 chars, redacted).
  final String bodyExcerpt;

  /// Request latency.
  final Duration latency;

  /// Creates [ResponseMetadata].
  const ResponseMetadata({
    required this.statusCode,
    required this.headers,
    required this.bodyExcerpt,
    required this.latency,
  });
}

/// Base sealed class for all GoogleAI exceptions.
sealed class GoogleAIException implements Exception {
  /// Creates a [GoogleAIException].
  const GoogleAIException();

  /// Human-readable error message.
  String get message;

  /// Optional stack trace.
  StackTrace? get stackTrace;

  /// Original exception that caused this exception (for exception chaining).
  /// Used to preserve context through retry attempts and error transformations.
  Exception? get cause;

  @override
  String toString() => 'GoogleAIException: $message';
}

/// Exception for HTTP/API errors.
class ApiException extends GoogleAIException {
  /// HTTP status code.
  final int code;

  @override
  final String message;

  /// Additional error details from the server.
  final List<Object> details;

  @override
  final StackTrace? stackTrace;

  /// Request metadata (for debugging).
  final RequestMetadata? requestMetadata;

  /// Response metadata (for debugging).
  final ResponseMetadata? responseMetadata;

  @override
  final Exception? cause;

  /// Creates an [ApiException].
  const ApiException({
    required this.code,
    required this.message,
    this.details = const [],
    this.stackTrace,
    this.requestMetadata,
    this.responseMetadata,
    this.cause,
  }) : super();

  @override
  String toString() {
    final buffer = StringBuffer('ApiException($code): $message');
    if (requestMetadata != null) {
      buffer
        ..write(
          '\n  Request: ${requestMetadata!.method} ${requestMetadata!.url}',
        )
        ..write('\n  Request ID: ${requestMetadata!.correlationId}');
    }
    if (responseMetadata != null) {
      buffer.write(
        '\n  Latency: ${responseMetadata!.latency.inMilliseconds}ms',
      );
    }
    if (cause != null) {
      buffer.write('\n  Caused by: $cause');
    }
    return buffer.toString();
  }
}

/// Exception for client-side validation errors.
class ValidationException extends GoogleAIException {
  @override
  final String message;

  /// Field-specific validation errors.
  final Map<String, List<String>> fieldErrors;

  @override
  final StackTrace? stackTrace;

  @override
  final Exception? cause;

  /// Creates a [ValidationException].
  const ValidationException({
    required this.message,
    required this.fieldErrors,
    this.stackTrace,
    this.cause,
  }) : super();

  @override
  String toString() => 'ValidationException: $message\nFields: $fieldErrors';
}

/// Exception for rate limit (429) errors.
class RateLimitException extends ApiException {
  /// When to retry (if provided by server).
  final DateTime? retryAfter;

  /// Creates a [RateLimitException].
  const RateLimitException({
    required super.code,
    required super.message,
    super.details,
    super.stackTrace,
    super.requestMetadata,
    super.responseMetadata,
    super.cause,
    this.retryAfter,
  });

  @override
  String toString() {
    final buffer = StringBuffer('RateLimitException($code): $message');
    if (retryAfter != null) {
      buffer.write(' (retry after: $retryAfter)');
    }
    if (requestMetadata != null) {
      buffer.write('\n  Request ID: ${requestMetadata!.correlationId}');
    }
    return buffer.toString();
  }
}

/// Exception for request timeouts.
class TimeoutException extends GoogleAIException {
  @override
  final String message;

  /// Configured timeout duration.
  final Duration timeout;

  /// Elapsed time before timeout.
  final Duration elapsed;

  @override
  final StackTrace? stackTrace;

  @override
  final Exception? cause;

  /// Creates a [TimeoutException].
  const TimeoutException({
    required this.message,
    required this.timeout,
    required this.elapsed,
    this.stackTrace,
    this.cause,
  }) : super();

  @override
  String toString() =>
      'TimeoutException: $message (timeout: $timeout, elapsed: $elapsed)';
}

/// Stage at which request was aborted.
enum AbortionStage {
  /// Aborted before network request was sent.
  beforeRequest,

  /// Aborted during request transmission.
  duringRequest,

  /// Aborted during response reception.
  duringResponse,

  /// Aborted during streaming response consumption.
  duringStream,
}

/// Exception thrown when a request is aborted by user.
class AbortedException extends GoogleAIException {
  @override
  final String message;

  /// Correlation ID for tracking.
  final String correlationId;

  /// When the request was aborted.
  final DateTime timestamp;

  /// Whether abortion occurred before or during response.
  final AbortionStage stage;

  /// Original abort reason, if provided.
  final Object? reason;

  @override
  final StackTrace? stackTrace;

  @override
  final Exception? cause;

  /// Creates an [AbortedException].
  const AbortedException({
    required this.message,
    required this.correlationId,
    required this.timestamp,
    required this.stage,
    this.reason,
    this.stackTrace,
    this.cause,
  }) : super();

  /// Creates from http RequestAbortedException.
  factory AbortedException.fromHttpException(
    Exception httpException, {
    required String correlationId,
    required AbortionStage stage,
  }) {
    return AbortedException(
      message: httpException.toString(),
      correlationId: correlationId,
      timestamp: DateTime.now(),
      stage: stage,
      reason: httpException,
    );
  }

  @override
  String toString() =>
      'AbortedException($stage): $message [ID: $correlationId]';
}

// =============================================================================
// Live API Exceptions
// =============================================================================

/// Exception thrown when the Live session is closed.
class LiveSessionClosedException extends GoogleAIException {
  /// WebSocket close code.
  final int? code;

  /// Close reason message.
  final String? reason;

  @override
  String get message =>
      'Live session closed${code != null ? ' (code: $code)' : ''}'
      '${reason != null ? ': $reason' : ''}';

  @override
  final StackTrace? stackTrace;

  @override
  final Exception? cause;

  /// Creates a [LiveSessionClosedException].
  const LiveSessionClosedException({
    this.code,
    this.reason,
    this.stackTrace,
    this.cause,
  }) : super();

  @override
  String toString() => 'LiveSessionClosedException: $message';
}

/// Exception thrown when session setup fails.
class LiveSessionSetupException extends GoogleAIException {
  @override
  final String message;

  /// Additional error details from the server.
  final Map<String, dynamic>? details;

  @override
  final StackTrace? stackTrace;

  @override
  final Exception? cause;

  /// Creates a [LiveSessionSetupException].
  const LiveSessionSetupException({
    required this.message,
    this.details,
    this.stackTrace,
    this.cause,
  }) : super();

  @override
  String toString() => 'LiveSessionSetupException: $message';
}

/// Exception thrown for general Live session errors.
class LiveSessionException extends GoogleAIException {
  @override
  final String message;

  @override
  final StackTrace? stackTrace;

  @override
  final Exception? cause;

  /// Creates a [LiveSessionException].
  const LiveSessionException({
    required this.message,
    this.stackTrace,
    this.cause,
  }) : super();

  @override
  String toString() => 'LiveSessionException: $message';
}

/// Exception thrown when session resumption fails.
class LiveSessionResumptionException extends GoogleAIException {
  @override
  final String message;

  /// The handle that failed to resume.
  final String? handle;

  @override
  final StackTrace? stackTrace;

  @override
  final Exception? cause;

  /// Creates a [LiveSessionResumptionException].
  const LiveSessionResumptionException({
    required this.message,
    this.handle,
    this.stackTrace,
    this.cause,
  }) : super();

  @override
  String toString() => 'LiveSessionResumptionException: $message';
}

/// Exception thrown when WebSocket connection fails.
class LiveConnectionException extends GoogleAIException {
  @override
  final String message;

  /// The URI that failed to connect.
  final Uri? uri;

  @override
  final StackTrace? stackTrace;

  @override
  final Exception? cause;

  /// Creates a [LiveConnectionException].
  const LiveConnectionException({
    required this.message,
    this.uri,
    this.stackTrace,
    this.cause,
  }) : super();

  @override
  String toString() => 'LiveConnectionException: $message';
}
