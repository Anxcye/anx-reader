// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import '../copy_with_sentinel.dart';
import 'grantee_type.dart';
import 'permission_role.dart';

/// Permission resource grants user, group or everyone access to a resource.
///
/// A role is a collection of permitted operations that allows users to perform
/// specific actions on resources. There are three concentric roles:
/// - Reader can use the resource for inference
/// - Writer has reader's permissions and can additionally edit and share
/// - Owner has writer's permissions and can additionally delete
class Permission {
  /// The permission name. Format:
  /// - `tunedModels/{tuned_model}/permissions/{permission}`
  /// - `corpora/{corpus}/permissions/{permission}`
  ///
  /// This is generated on create and is read-only.
  final String? name;

  /// The type of the grantee (user, group, or everyone).
  final GranteeType? granteeType;

  /// The email address of the user or group.
  ///
  /// Required when granteeType is USER or GROUP.
  /// Not set when granteeType is EVERYONE.
  final String? emailAddress;

  /// The role granted by this permission.
  final PermissionRole? role;

  /// Creates a [Permission].
  const Permission({this.name, this.granteeType, this.emailAddress, this.role});

  /// Creates a [Permission] from JSON.
  factory Permission.fromJson(Map<String, dynamic> json) => Permission(
    name: json['name'] as String?,
    granteeType: json['granteeType'] != null
        ? granteeTypeFromString(json['granteeType'] as String)
        : null,
    emailAddress: json['emailAddress'] as String?,
    role: json['role'] != null
        ? permissionRoleFromString(json['role'] as String)
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (granteeType != null) 'granteeType': granteeTypeToString(granteeType!),
    if (emailAddress != null) 'emailAddress': emailAddress,
    if (role != null) 'role': permissionRoleToString(role!),
  };

  @override
  String toString() =>
      'Permission(name: $name, granteeType: $granteeType, emailAddress: $emailAddress, role: $role)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Permission &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          granteeType == other.granteeType &&
          emailAddress == other.emailAddress &&
          role == other.role;

  @override
  int get hashCode =>
      name.hashCode ^
      granteeType.hashCode ^
      emailAddress.hashCode ^
      role.hashCode;

  /// Creates a copy with replaced values.
  Permission copyWith({
    Object? name = unsetCopyWithValue,
    Object? granteeType = unsetCopyWithValue,
    Object? emailAddress = unsetCopyWithValue,
    Object? role = unsetCopyWithValue,
  }) {
    return Permission(
      name: name == unsetCopyWithValue ? this.name : name as String?,
      granteeType: granteeType == unsetCopyWithValue
          ? this.granteeType
          : granteeType as GranteeType?,
      emailAddress: emailAddress == unsetCopyWithValue
          ? this.emailAddress
          : emailAddress as String?,
      role: role == unsetCopyWithValue ? this.role : role as PermissionRole?,
    );
  }
}
