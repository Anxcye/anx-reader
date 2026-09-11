import 'package:meta/meta.dart';

import 'auth_token.dart';

/// Request wrapper for creating an ephemeral authentication token.
///
/// Used with the [AuthTokensResource.create] method.
@immutable
class CreateAuthTokenRequest {
  /// The token configuration to create.
  final AuthToken authToken;

  /// Creates a [CreateAuthTokenRequest] with the given token configuration.
  const CreateAuthTokenRequest({required this.authToken});

  /// Creates a CreateAuthTokenRequest from JSON.
  factory CreateAuthTokenRequest.fromJson(Map<String, dynamic> json) {
    return CreateAuthTokenRequest(
      authToken: AuthToken.fromJson(json['authToken'] as Map<String, dynamic>),
    );
  }

  /// Converts this request to JSON.
  Map<String, dynamic> toJson() {
    return <String, dynamic>{'authToken': authToken.toJson()};
  }

  @override
  String toString() => 'CreateAuthTokenRequest(authToken: $authToken)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CreateAuthTokenRequest && other.authToken == authToken;
  }

  @override
  int get hashCode => authToken.hashCode;
}
