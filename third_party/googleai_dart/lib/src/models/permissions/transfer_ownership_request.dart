// ignore_for_file: avoid_equals_and_hash_code_on_mutable_classes

import '../copy_with_sentinel.dart';

/// Request to transfer ownership of a resource.
class TransferOwnershipRequest {
  /// The email address of the new owner.
  final String emailAddress;

  /// Creates a [TransferOwnershipRequest].
  const TransferOwnershipRequest({required this.emailAddress});

  /// Creates a [TransferOwnershipRequest] from JSON.
  factory TransferOwnershipRequest.fromJson(Map<String, dynamic> json) =>
      TransferOwnershipRequest(emailAddress: json['emailAddress'] as String);

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {'emailAddress': emailAddress};

  @override
  String toString() => 'TransferOwnershipRequest(emailAddress: $emailAddress)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TransferOwnershipRequest &&
          runtimeType == other.runtimeType &&
          emailAddress == other.emailAddress;

  @override
  int get hashCode => emailAddress.hashCode;

  /// Creates a copy with replaced values.
  TransferOwnershipRequest copyWith({
    Object? emailAddress = unsetCopyWithValue,
  }) {
    return TransferOwnershipRequest(
      emailAddress: emailAddress == unsetCopyWithValue
          ? this.emailAddress
          : emailAddress! as String,
    );
  }
}
