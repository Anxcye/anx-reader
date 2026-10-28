/// The role granted by a permission.
///
/// There are three concentric roles, where each role is a superset
/// of the previous role's permitted operations:
/// - Reader can use the resource for inference
/// - Writer has reader's permissions and can additionally edit and share
/// - Owner has writer's permissions and can additionally delete
enum PermissionRole {
  /// Unspecified role.
  unspecified,

  /// Owner can use, update, share and delete the resource.
  owner,

  /// Writer can use, update and share the resource.
  writer,

  /// Reader can use the resource.
  reader,
}

/// Converts a string to [PermissionRole].
PermissionRole permissionRoleFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'OWNER' => PermissionRole.owner,
    'WRITER' => PermissionRole.writer,
    'READER' => PermissionRole.reader,
    _ => PermissionRole.unspecified,
  };
}

/// Converts [PermissionRole] to a string.
String permissionRoleToString(PermissionRole role) {
  return switch (role) {
    PermissionRole.owner => 'OWNER',
    PermissionRole.writer => 'WRITER',
    PermissionRole.reader => 'READER',
    PermissionRole.unspecified => 'ROLE_UNSPECIFIED',
  };
}
