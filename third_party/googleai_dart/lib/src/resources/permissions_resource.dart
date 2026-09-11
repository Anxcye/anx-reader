import 'dart:convert';

import 'package:http/http.dart' as http;

import '../models/permissions/list_permissions_response.dart';
import '../models/permissions/permission.dart';
import '../models/permissions/transfer_ownership_request.dart';
import 'base_resource.dart';

/// Resource for the Permissions API.
///
/// Provides access to permission management for tuned models and corpora.
class PermissionsResource extends ResourceBase {
  /// Parent resource name (e.g., "tunedModels/my-model", "corpora/my-corpus").
  final String parent;

  /// Creates a [PermissionsResource].
  PermissionsResource({
    required this.parent,
    required super.config,
    required super.httpClient,
    required super.interceptorChain,
    required super.requestBuilder,
  });

  /// Creates a permission for a resource (tuned model or corpus).
  ///
  /// [permission] - The permission to create
  ///
  /// POST /v1beta/{parent}/permissions
  Future<Permission> create({required Permission permission}) async {
    final url = requestBuilder.buildUrl('/{version}/$parent/permissions');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(permission.toJson());

    final response = await interceptorChain.execute(httpRequest);
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    return Permission.fromJson(responseData);
  }

  /// Lists permissions for a resource.
  ///
  /// [pageSize] - Maximum number of permissions to return (default 50, max 1000)
  /// [pageToken] - Page token from a previous listPermissions call
  ///
  /// GET /v1beta/{parent}/permissions
  Future<ListPermissionsResponse> list({
    int? pageSize,
    String? pageToken,
  }) async {
    final queryParams = <String, String>{
      if (pageSize != null) 'pageSize': pageSize.toString(),
      if (pageToken != null) 'pageToken': pageToken,
    };

    final url = requestBuilder.buildUrl(
      '/{version}/$parent/permissions',
      queryParams: queryParams,
    );

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    return ListPermissionsResponse.fromJson(responseData);
  }

  /// Gets a specific permission.
  ///
  /// [name] - Permission resource name (e.g., `tunedModels/{model}/permissions/{permission}`)
  ///
  /// GET /v1beta/{name}
  Future<Permission> get({required String name}) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('GET', url)..headers.addAll(headers);

    final response = await interceptorChain.execute(httpRequest);
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    return Permission.fromJson(responseData);
  }

  /// Updates a permission.
  ///
  /// [name] - Permission resource name (e.g., `tunedModels/{model}/permissions/{permission}`)
  /// [permission] - The updated permission
  ///
  /// PATCH /v1beta/{name}
  Future<Permission> update({
    required String name,
    required Permission permission,
  }) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final httpRequest = http.Request('PATCH', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(permission.toJson());

    final response = await interceptorChain.execute(httpRequest);
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    return Permission.fromJson(responseData);
  }

  /// Deletes a permission.
  ///
  /// [name] - Permission resource name (e.g., `tunedModels/{model}/permissions/{permission}`)
  ///
  /// DELETE /v1beta/{name}
  Future<void> delete({required String name}) async {
    final url = requestBuilder.buildUrl('/{version}/$name');

    final headers = requestBuilder.buildHeaders();

    final httpRequest = http.Request('DELETE', url)..headers.addAll(headers);

    await interceptorChain.execute(httpRequest);
  }

  /// Transfers ownership of a resource to another user.
  ///
  /// [name] - Resource name (e.g., `tunedModels/{model}` or `corpora/{corpus}`)
  /// [emailAddress] - Email address of the new owner
  ///
  /// POST /v1beta/{name}:transferOwnership
  Future<Permission> transferOwnership({
    required String name,
    required String emailAddress,
  }) async {
    final url = requestBuilder.buildUrl('/{version}/$name:transferOwnership');

    final headers = requestBuilder.buildHeaders(
      additionalHeaders: {'Content-Type': 'application/json'},
    );

    final request = TransferOwnershipRequest(emailAddress: emailAddress);

    final httpRequest = http.Request('POST', url)
      ..headers.addAll(headers)
      ..body = jsonEncode(request.toJson());

    final response = await interceptorChain.execute(httpRequest);
    final responseData = jsonDecode(response.body) as Map<String, dynamic>;

    return Permission.fromJson(responseData);
  }
}
