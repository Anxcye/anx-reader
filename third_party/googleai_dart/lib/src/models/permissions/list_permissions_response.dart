// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import '../copy_with_sentinel.dart';
import 'permission.dart';

/// Response message for listing permissions.
class ListPermissionsResponse {
  /// List of permissions for the resource.
  final List<Permission>? permissions;

  /// Token for the next page. Empty if there are no more pages.
  final String? nextPageToken;

  /// Creates a [ListPermissionsResponse].
  const ListPermissionsResponse({this.permissions, this.nextPageToken});

  /// Creates a [ListPermissionsResponse] from JSON.
  factory ListPermissionsResponse.fromJson(Map<String, dynamic> json) =>
      ListPermissionsResponse(
        permissions: json['permissions'] != null
            ? (json['permissions'] as List)
                  .map((e) => Permission.fromJson(e as Map<String, dynamic>))
                  .toList()
            : null,
        nextPageToken: json['nextPageToken'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (permissions != null)
      'permissions': permissions!.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
  };

  @override
  String toString() =>
      'ListPermissionsResponse(permissions: $permissions, nextPageToken: $nextPageToken)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ListPermissionsResponse &&
          runtimeType == other.runtimeType &&
          permissions == other.permissions &&
          nextPageToken == other.nextPageToken;

  @override
  int get hashCode => permissions.hashCode ^ nextPageToken.hashCode;

  /// Creates a copy with replaced values.
  ListPermissionsResponse copyWith({
    Object? permissions = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
  }) {
    return ListPermissionsResponse(
      permissions: permissions == unsetCopyWithValue
          ? this.permissions
          : permissions as List<Permission>?,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
    );
  }
}
