import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';
import '../client/config.dart';
import '../errors/exceptions.dart';
import '../utils/redactor.dart';
import 'interceptor.dart';

/// Interceptor that logs HTTP requests and responses.
class LoggingInterceptor implements Interceptor {
  /// Logger instance.
  final Logger logger;

  /// Redactor for sensitive data.
  final Redactor redactor;

  /// Configuration.
  final GoogleAIConfig config;

  /// Creates a [LoggingInterceptor].
  LoggingInterceptor({required this.config})
    : logger = Logger('GoogleAI.HTTP'),
      redactor = Redactor(redactionList: config.redactionList) {
    // Only set level if hierarchical logging is enabled
    // or if this is the root logger
    if (hierarchicalLoggingEnabled || logger.parent == null) {
      logger.level = config.logLevel;
    }
  }

  @override
  Future<http.Response> intercept(
    RequestContext context,
    InterceptorNext next,
  ) async {
    final request = context.request;
    final stopwatch = Stopwatch()..start();

    // Add request ID if not present
    final requestId = _getOrCreateRequestId(request);

    // Add X-Request-ID header if not already present
    var updatedRequest = request;
    if (!request.headers.containsKey('X-Request-ID')) {
      updatedRequest = _addRequestIdHeader(request, requestId);
    }

    // Update context with new request and metadata
    final timestamp = DateTime.now();
    final updatedContext = context.copyWith(
      request: updatedRequest,
      metadata: {
        ...context.metadata,
        'correlationId': requestId,
        'timestamp': timestamp,
        'startTime': stopwatch.elapsedMilliseconds,
      },
    );

    // Log request
    _logRequest(updatedRequest, requestId);

    try {
      // Execute request
      final response = await next(updatedContext);
      stopwatch.stop();

      // Log response
      _logResponse(response, requestId, stopwatch.elapsedMilliseconds);

      return response;
    } on AbortedException catch (e) {
      // Log abortion specifically
      stopwatch.stop();
      logger.warning(
        'ABORTED [$requestId] ${e.stage} after ${stopwatch.elapsedMilliseconds}ms',
        e,
        e.stackTrace,
      );
      rethrow;
    } catch (error) {
      stopwatch.stop();
      _logError(error, requestId, stopwatch.elapsedMilliseconds);
      rethrow;
    }
  }

  /// Gets existing request ID or creates a new one.
  String _getOrCreateRequestId(http.BaseRequest request) {
    // Check if X-Request-ID already exists
    if (request.headers.containsKey('X-Request-ID')) {
      return request.headers['X-Request-ID']!;
    }

    // Generate new request ID using timestamp
    // NOTE: This provides sufficient uniqueness for request correlation
    // in a single-threaded Dart environment. Collision risk is minimal
    // (millisecond precision). Using UUID would require additional dependency,
    // which violates minimal-dependency principle. This is acceptable for Phase 2.
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    return 'req_$timestamp';
  }

  /// Adds X-Request-ID header to request.
  http.BaseRequest _addRequestIdHeader(
    http.BaseRequest request,
    String requestId,
  ) {
    if (request is http.Request) {
      return http.Request(request.method, request.url)
        ..headers.addAll(request.headers)
        ..headers['X-Request-ID'] = requestId
        ..bodyBytes = request.bodyBytes
        ..encoding = request.encoding;
    }

    // For other request types, return as-is (can't modify)
    return request;
  }

  /// Logs HTTP request.
  void _logRequest(http.BaseRequest request, String requestId) {
    if (logger.level <= Level.INFO) {
      final headers = redactor.redactMap(request.headers);
      logger
        ..info('REQUEST [$requestId] ${request.method} ${request.url}')
        ..fine('Headers: $headers');
    }
  }

  /// Logs HTTP response.
  void _logResponse(http.Response response, String requestId, int durationMs) {
    if (logger.level <= Level.INFO) {
      final headers = redactor.redactMap(response.headers);
      logger
        ..info('RESPONSE [$requestId] ${response.statusCode} (${durationMs}ms)')
        ..fine('Headers: $headers');

      if (logger.level <= Level.FINE) {
        final body = redactor.truncate(
          redactor.redactString(response.body),
          500,
        );
        logger.fine('Body: $body');
      }
    }
  }

  /// Logs error.
  void _logError(Object error, String requestId, int durationMs) {
    logger.severe(
      'ERROR [$requestId] $error (${durationMs}ms)',
      error,
      error is Error ? error.stackTrace : null,
    );
  }
}
