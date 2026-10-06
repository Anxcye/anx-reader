import 'dart:async';
import 'dart:convert';
import 'dart:io' as io;

import 'package:http/http.dart' as http;

import '../../auth/auth_provider.dart';
import '../../client/config.dart';
import '../../errors/exceptions.dart';
import '../../models/files/file.dart' as file_model;
import '../../models/files/list_files_response.dart';
import '../base_resource.dart';

/// Resource for the Files API (IO implementation).
///
/// Provides access to file upload, listing, and management operations.
///
/// **Note**: This resource is only available with the Google AI (Gemini) API.
/// Vertex AI does not have a Files API. For Vertex AI, use Cloud Storage URIs
/// or base64-encoded data directly in your requests.
///
/// See: https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/send-multimodal-prompts
class FilesResource extends ResourceBase {
  /// Creates a [FilesResource].
  FilesResource({
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Validates that the Files API is only used with Google AI.
  void _validateGoogleAIOnly() {
    if (config.apiMode == ApiMode.vertexAI) {
      throw UnsupportedError(
        'Files API is only available with Google AI (Gemini API). '
        'Vertex AI does not have a Files API. '
        'For Vertex AI, use Cloud Storage URIs (gs://...) or base64-encoded data directly. '
        'See: https://cloud.google.com/vertex-ai/generative-ai/docs/multimodal/send-multimodal-prompts',
      );
    }
  }

  /// Uploads a file for use in prompts.
  ///
  /// This method supports three input modes (exactly one must be provided):
  /// - [filePath]: Path to a file on the file system (backwards compatible, streaming)
  /// - [contentStream]: A stream of bytes for streaming uploads (memory efficient)
  /// - [bytes]: The file content as a list of bytes (compatible with web API)
  ///
  /// Required parameters:
  /// - [mimeType]: The MIME type of the file (e.g., "image/jpeg")
  /// - [fileName]: Required when using [contentStream] or [bytes], otherwise extracted from [filePath]
  ///
  /// Optional parameters:
  /// - [displayName]: Human-readable name for the file
  ///
  /// Returns a [File] with metadata about the uploaded file.
  ///
  /// Note: Uploaded files are automatically deleted after 48 hours.
  ///
  /// Throws:
  /// - [ValidationException] if file not found or invalid parameters
  /// - [UnsupportedError] if used with Vertex AI
  ///
  /// Examples:
  /// ```dart
  /// // From file path (backwards compatible, streaming)
  /// final file1 = await client.files.upload(
  ///   filePath: '/path/to/image.jpg',
  ///   mimeType: 'image/jpeg',
  /// );
  ///
  /// // From stream (memory efficient for large files)
  /// final stream = io.File('/path/to/large-video.mp4').openRead();
  /// final file2 = await client.files.upload(
  ///   contentStream: stream,
  ///   fileName: 'video.mp4',
  ///   mimeType: 'video/mp4',
  /// );
  ///
  /// // From bytes (compatible with web API)
  /// final bytes = await io.File('/path/to/document.pdf').readAsBytes();
  /// final file3 = await client.files.upload(
  ///   bytes: bytes,
  ///   fileName: 'document.pdf',
  ///   mimeType: 'application/pdf',
  /// );
  /// ```
  Future<file_model.File> upload({
    String? filePath,
    Stream<List<int>>? contentStream,
    List<int>? bytes,
    String? fileName,
    required String mimeType,
    String? displayName,
  }) async {
    _validateGoogleAIOnly();

    // Validate that exactly one input method is provided
    final inputCount = [
      filePath,
      contentStream,
      bytes,
    ].where((input) => input != null).length;

    if (inputCount != 1) {
      throw const ValidationException(
        message:
            'Exactly one of filePath, contentStream, or bytes must be provided',
        fieldErrors: {
          'upload': [
            'Provide exactly one of: filePath, contentStream, or bytes',
          ],
        },
      );
    }

    // Prepare the upload data
    final Stream<List<int>> dataStream;
    final int contentLength;
    final String finalFileName;

    if (filePath != null) {
      // File path mode - use streaming
      final file = io.File(filePath);
      if (!file.existsSync()) {
        throw const ValidationException(
          message: 'File not found',
          fieldErrors: {
            'filePath': ['File does not exist'],
          },
        );
      }
      dataStream = file.openRead();
      contentLength = await file.length();
      finalFileName = fileName ?? file.uri.pathSegments.last;
    } else if (contentStream != null) {
      // Stream mode
      if (fileName == null) {
        throw const ValidationException(
          message: 'fileName is required when using contentStream',
          fieldErrors: {
            'fileName': ['fileName must be provided with contentStream'],
          },
        );
      }
      // For streams, we need to buffer to get length (limitation of resumable upload)
      // In the future, could use chunked transfer encoding if API supports it
      final bufferedBytes = await contentStream.fold<List<int>>(
        [],
        (buffer, chunk) => buffer..addAll(chunk),
      );
      dataStream = Stream.value(bufferedBytes);
      contentLength = bufferedBytes.length;
      finalFileName = fileName;
    } else {
      // Bytes mode
      if (fileName == null) {
        throw const ValidationException(
          message: 'fileName is required when using bytes',
          fieldErrors: {
            'fileName': ['fileName must be provided with bytes'],
          },
        );
      }
      dataStream = Stream.value(bytes!);
      contentLength = bytes.length;
      finalFileName = fileName;
    }

    final displayFileName = displayName ?? finalFileName;

    // Google AI Files API uses resumable upload protocol
    // Step 1: Initiate the upload and get upload URL
    final uploadUrl = Uri.parse(
      '${config.baseUrl}/upload/${config.apiVersion.value}/files',
    );

    final initiationHeaders = <String, String>{
      'X-Goog-Upload-Protocol': 'resumable',
      'X-Goog-Upload-Command': 'start',
      'X-Goog-Upload-Header-Content-Length': contentLength.toString(),
      'X-Goog-Upload-Header-Content-Type': mimeType,
      'Content-Type': 'application/json',
    };

    // Apply authentication to initiation request
    if (config.authProvider != null) {
      final credentials = await config.authProvider!.getCredentials();
      switch (credentials) {
        case ApiKeyCredentials(:final apiKey, :final placement):
          if (placement == AuthPlacement.header) {
            initiationHeaders['X-Goog-Api-Key'] = apiKey;
          }
        case BearerTokenCredentials(:final token):
          initiationHeaders['Authorization'] = 'Bearer $token';
        case EphemeralTokenCredentials(:final token, :final placement):
          if (placement == EphemeralTokenPlacement.header) {
            initiationHeaders['Authorization'] = 'Token $token';
          }
        // Query param handled below
        case NoAuthCredentials():
          // No auth needed
          break;
      }
    }

    // Add API key or ephemeral token as query param if needed
    final Uri uploadUrlWithAuth;
    if (config.authProvider != null) {
      final credentials = await config.authProvider!.getCredentials();
      if (credentials is ApiKeyCredentials &&
          credentials.placement == AuthPlacement.queryParam) {
        uploadUrlWithAuth = uploadUrl.replace(
          queryParameters: {'key': credentials.apiKey},
        );
      } else if (credentials is EphemeralTokenCredentials &&
          credentials.placement == EphemeralTokenPlacement.queryParam) {
        uploadUrlWithAuth = uploadUrl.replace(
          queryParameters: {'access_token': credentials.token},
        );
      } else {
        uploadUrlWithAuth = uploadUrl;
      }
    } else {
      uploadUrlWithAuth = uploadUrl;
    }

    final initiationBody = jsonEncode({
      'file': {'displayName': displayFileName},
    });

    final initiationRequest = http.Request('POST', uploadUrlWithAuth)
      ..headers.addAll(initiationHeaders)
      ..body = initiationBody;

    final initiationResponse = await httpClient.send(initiationRequest);
    final initResponse = await http.Response.fromStream(initiationResponse);

    if (initResponse.statusCode >= 400) {
      throw _mapHttpErrorForStreaming(initResponse);
    }

    // Extract upload URL from response headers
    final uploadUrlHeader = initResponse.headers['x-goog-upload-url'];
    if (uploadUrlHeader == null) {
      throw const ApiException(
        code: 500,
        message: 'Upload URL not returned in initiation response',
      );
    }

    // Step 2: Upload the file bytes (streaming)
    final uploadHeaders = <String, String>{
      'Content-Length': contentLength.toString(),
      'X-Goog-Upload-Offset': '0',
      'X-Goog-Upload-Command': 'upload, finalize',
    };

    final uploadRequest =
        http.StreamedRequest('POST', Uri.parse(uploadUrlHeader))
          ..headers.addAll(uploadHeaders)
          ..contentLength = contentLength;

    // Stream the data
    dataStream.listen(
      uploadRequest.sink.add,
      onError: uploadRequest.sink.addError,
      onDone: uploadRequest.sink.close,
      cancelOnError: true,
    );

    final uploadResponse = await httpClient.send(uploadRequest);
    final finalResponse = await http.Response.fromStream(uploadResponse);

    if (finalResponse.statusCode >= 400) {
      throw _mapHttpErrorForStreaming(finalResponse);
    }

    final responseBody = jsonDecode(finalResponse.body) as Map<String, dynamic>;
    return file_model.File.fromJson(
      responseBody['file'] as Map<String, dynamic>,
    );
  }

  /// Lists uploaded files.
  ///
  /// The [pageSize] parameter specifies the maximum number of files to return
  /// (default is 50). The [pageToken] is used for pagination.
  ///
  /// Returns a [ListFilesResponse] with the list of files and a next page token.
  Future<ListFilesResponse> list({int? pageSize, String? pageToken}) async {
    _validateGoogleAIOnly();

    final queryParams = <String, String>{
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/files',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListFilesResponse.fromJson(responseBody);
  }

  /// Gets metadata for a specific file.
  ///
  /// The [name] is the resource name of the file (e.g., "files/abc123").
  ///
  /// Returns a [File] with the file's metadata.
  Future<file_model.File> get({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return file_model.File.fromJson(responseBody);
  }

  /// Deletes a file.
  ///
  /// The [name] is the resource name of the file to delete (e.g., "files/abc123").
  Future<void> delete({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('DELETE', url)..headers.addAll(headers);

    await interceptorChain.execute(httpRequest);
  }

  /// Downloads the content of a file.
  ///
  /// The [name] is the resource name of the file to download (e.g., "files/abc123").
  ///
  /// Returns the file content as a list of bytes.
  ///
  /// **Note:** Files are automatically deleted after 48 hours.
  Future<List<int>> download({required String name}) async {
    _validateGoogleAIOnly();

    final url = requestBuilder.buildUrl('/{version}/$name:download');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    // Return the raw bytes
    return response.bodyBytes;
  }

  /// Maps HTTP errors for streaming (mirrors ErrorInterceptor logic).
  GoogleAIException _mapHttpErrorForStreaming(http.Response response) {
    final statusCode = response.statusCode;
    final body = response.body;

    // Try to parse error details from response body
    var message = 'HTTP $statusCode error';
    final details = <Object>[];

    try {
      final errorDetails = jsonDecode(body);
      if (errorDetails is Map<String, dynamic>) {
        final error = errorDetails['error'] as Map<String, dynamic>?;
        message = error?['message']?.toString() ?? message;
        if (error?['details'] != null) {
          final errorDetailsList = error!['details'];
          if (errorDetailsList is List) {
            details.addAll(errorDetailsList.cast<Object>());
          }
        }
      }
    } catch (_) {
      if (body.length < 200 && body.isNotEmpty) {
        message = body;
      }
    }

    // Map to specific exception types
    if (statusCode == 429) {
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
      );
    }

    return ApiException(code: statusCode, message: message, details: details);
  }
}
