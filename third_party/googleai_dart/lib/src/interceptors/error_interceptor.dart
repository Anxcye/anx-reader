import 'dart:convert';
import 'package:http/http.dart' as http;
import '../errors/exceptions.dart';
import '../utils/redactor.dart';
import '../utils/request_id.dart';
import 'interceptor.dart';

/// Interceptor that maps HTTP errors to domain exceptions.
class ErrorInterceptor implements Interceptor {
  /// Creates an [ErrorInterceptor].
  const ErrorInterceptor();

  @override
  Future<http.Response> intercept(
    RequestContext context,
    InterceptorNext next,
  ) async {
    final startTime = DateTime.now();

    try {
      final response = await next(context);

      // Check for HTTP errors
      if (response.statusCode >= 400) {
        final latency = DateTime.now().difference(startTime);
        throw _mapHttpError(response, context, latency);
      }

      return response;
    } on GoogleAIException {
      // Re-throw our own exceptions
      rethrow;
    } catch (error, stackTrace) {
      // Wrap unknown errors
      throw ApiException(
        code: 0,
        message: 'Unexpected error: $error',
        stackTrace: stackTrace,
      );
    }
  }

  /// Maps HTTP response to appropriate exception.
  GoogleAIException _mapHttpError(
    http.Response response,
    RequestContext context,
    Duration latency,
  ) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Try to parse error details from response body
    Object? errorDetails;
    var message = 'HTTP $statusCode error';
    final details = <Object>[];

    try {
      errorDetails = jsonDecode(body);
      if (errorDetails is Map<String, dynamic>) {
        final error = errorDetails['error'];
        if (error is Map<String, dynamic>) {
          message = error['message']?.toString() ?? message;
          final errorDetailsList = error['details'];
          if (errorDetailsList is List) {
            details.addAll(errorDetailsList.cast<Object>());
          }
        }
      }
    } catch (_) {
      // If body is not JSON, use it as message if short enough
      if (body.length < 200) {
        message = body.isNotEmpty ? body : message;
      }
    }

    // Extract request metadata from context
    final correlationId =
        context.metadata['correlationId'] as String? ??
        context.request.headers['X-Request-ID'] ??
        generateRequestId();
    final timestamp =
        context.metadata['timestamp'] as DateTime? ?? DateTime.now();
    final attemptNumber = context.metadata['attemptNumber'] as int? ?? 0;

    // Redact sensitive headers
    const redactor = Redactor(
      redactionList: [
        'authorization',
        'api-key',
        'api_key',
        'x-goog-api-key',
        'token',
      ],
    );
    final redactedHeaders = redactor.redactMap(context.request.headers);

    // Create request metadata
    final requestMetadata = RequestMetadata(
      method: context.request.method,
      url: context.request.url,
      headers: redactedHeaders,
      correlationId: correlationId,
      timestamp: timestamp,
      attemptNumber: attemptNumber,
    );

    // Create response metadata
    final bodyExcerpt = body.length > 200 ? body.substring(0, 200) : body;
    final responseMetadata = ResponseMetadata(
      statusCode: statusCode,
      headers: response.headers,
      bodyExcerpt: redactor.redactString(bodyExcerpt),
      latency: latency,
    );

    // Map to specific exception types
    if (statusCode == 429) {
      // Rate limit error
      DateTime? retryAfter;
      final retryHeader = response.headers['retry-after'];
      if (retryHeader != null) {
        final seconds = int.tryParse(retryHeader);
        if (seconds != null) {
          retryAfter = DateTime.now().add(Duration(seconds: seconds));
        }
      }

      return RateLimitException(
        code: statusCode,
        message: message,
        details: details,
        retryAfter: retryAfter,
        requestMetadata: requestMetadata,
        responseMetadata: responseMetadata,
      );
    }

    // Generic API exception
    return ApiException(
      code: statusCode,
      message: message,
      details: details,
      requestMetadata: requestMetadata,
      responseMetadata: responseMetadata,
    );
  }
}
