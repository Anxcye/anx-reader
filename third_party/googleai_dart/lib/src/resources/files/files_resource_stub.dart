import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../client/config.dart';
import '../../models/files/file.dart' as file_model;
import '../../models/files/list_files_response.dart';
import '../base_resource.dart';

/// Resource for the Files API.
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
  /// This method is not supported on this platform.
  ///
  /// Throws [UnsupportedError] always.
  Future<file_model.File> upload({
    String? filePath,
    Stream<List<int>>? contentStream,
    List<int>? bytes,
    String? fileName,
    required String mimeType,
    String? displayName,
  }) {
    throw UnsupportedError(
      'File upload is not supported on this platform. '
      'Use dart:io or web platform.',
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
}
