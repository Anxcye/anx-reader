import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/models/list_operations_response.dart';
import '../models/models/operation.dart';
import 'base_resource.dart';

/// Resource for the Operations API.
///
/// Provides access to long-running operation management.
class OperationsResource extends ResourceBase {
  /// Parent resource name (e.g., "models/gemini-pro", "tunedModels/my-model").
  final String parent;

  /// Creates an [OperationsResource].
  OperationsResource({
    required this.parent,
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Lists operations for the parent resource.
  ///
  /// The [pageSize] parameter specifies the maximum number of operations to return.
  /// The [pageToken] is used for pagination.
  /// The [filter] allows filtering operations.
  /// The [returnPartialSuccess] when set to true, operations that are reachable
  /// are returned as normal, and those that are unreachable are returned in the
  /// unreachable field.
  ///
  /// Returns a [ListOperationsResponse] with the list of operations.
  Future<ListOperationsResponse> list({
    int? pageSize,
    String? pageToken,
    String? filter,
    bool? returnPartialSuccess,
  }) async {
    final queryParams = <String, String>{
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
      if (filter != null) 'filter': filter,
      if (returnPartialSuccess != null)
        'returnPartialSuccess': returnPartialSuccess.toString(),
    };

    final url = requestBuilder.buildUrl(
      '/{version}/$parent/operations',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return ListOperationsResponse.fromJson(responseBody);
  }

  /// Gets the status of a long-running operation.
  ///
  /// The [name] is the operation resource name.
  ///
  /// Returns the [Operation] with its current status.
  Future<Operation> get({required String name}) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);

    final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
    return Operation.fromJson(responseBody);
  }
}
