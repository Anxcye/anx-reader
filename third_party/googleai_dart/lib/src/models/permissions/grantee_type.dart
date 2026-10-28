/// The type of grantee for a permission.
enum GranteeType {
  /// Unspecified grantee type.
  unspecified,

  /// Represents a user. Requires an email address.
  user,

  /// Represents a group. Requires an email address.
  group,

  /// Represents access to everyone. No email address required.
  everyone,
}

/// Converts a string to [GranteeType].
GranteeType granteeTypeFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'USER' => GranteeType.user,
    'GROUP' => GranteeType.group,
    'EVERYONE' => GranteeType.everyone,
    _ => GranteeType.unspecified,
  };
}

/// Converts [GranteeType] to a string.
String granteeTypeToString(GranteeType type) {
  return switch (type) {
    GranteeType.user => 'USER',
    GranteeType.group => 'GROUP',
    GranteeType.everyone => 'EVERYONE',
    GranteeType.unspecified => 'GRANTEE_TYPE_UNSPECIFIED',
  };
}
