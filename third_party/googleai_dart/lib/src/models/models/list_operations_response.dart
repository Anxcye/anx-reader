import '../copy_with_sentinel.dart';
import 'operation.dart';

/// Response from listing operations.
class ListOperationsResponse {
  /// A list of operations that matches the specified filter in the request.
  final List<Operation> operations;

  /// The standard List next-page token.
  final String? nextPageToken;

  /// Unordered list. Unreachable resources. Populated when the request sets
  /// `ListOperationsRequest.return_partial_success` and reads across
  /// collections e.g. when attempting to list all resources across all supported
  /// locations.
  final List<String>? unreachable;

  /// Creates a [ListOperationsResponse].
  const ListOperationsResponse({
    required this.operations,
    this.nextPageToken,
    this.unreachable,
  });

  /// Creates a [ListOperationsResponse] from JSON.
  factory ListOperationsResponse.fromJson(Map<String, dynamic> json) =>
      ListOperationsResponse(
        operations:
            (json['operations'] as List<dynamic>?)
                ?.map((e) => Operation.fromJson(e as Map<String, dynamic>))
                .toList() ??
            [],
        nextPageToken: json['nextPageToken'] as String?,
        unreachable: (json['unreachable'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'operations': operations.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
    if (unreachable != null) 'unreachable': unreachable,
  };

  /// Creates a copy with replaced values.
  ListOperationsResponse copyWith({
    Object? operations = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
    Object? unreachable = unsetCopyWithValue,
  }) {
    return ListOperationsResponse(
      operations: operations == unsetCopyWithValue
          ? this.operations
          : operations! as List<Operation>,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
      unreachable: unreachable == unsetCopyWithValue
          ? this.unreachable
          : unreachable as List<String>?,
    );
  }
}
