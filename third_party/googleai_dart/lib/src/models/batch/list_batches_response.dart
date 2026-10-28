import '../copy_with_sentinel.dart';
import '../models/operation.dart';

/// Response message for listing batch operations.
class ListBatchesResponse {
  /// A list of batch operations that matches the specified filter.
  final List<Operation>? operations;

  /// The standard list next-page token.
  final String? nextPageToken;

  /// Unreachable resources (populated when using partial success).
  final List<String>? unreachable;

  /// Creates a [ListBatchesResponse].
  const ListBatchesResponse({
    this.operations,
    this.nextPageToken,
    this.unreachable,
  });

  /// Creates a [ListBatchesResponse] from JSON.
  factory ListBatchesResponse.fromJson(Map<String, dynamic> json) =>
      ListBatchesResponse(
        operations: json['operations'] != null
            ? (json['operations'] as List)
                  .map((e) => Operation.fromJson(e as Map<String, dynamic>))
                  .toList()
            : null,
        nextPageToken: json['nextPageToken'] as String?,
        unreachable: json['unreachable'] != null
            ? (json['unreachable'] as List).map((e) => e as String).toList()
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (operations != null)
      'operations': operations!.map((e) => e.toJson()).toList(),
    if (nextPageToken != null) 'nextPageToken': nextPageToken,
    if (unreachable != null) 'unreachable': unreachable,
  };

  /// Creates a copy with replaced values.
  ListBatchesResponse copyWith({
    Object? operations = unsetCopyWithValue,
    Object? nextPageToken = unsetCopyWithValue,
    Object? unreachable = unsetCopyWithValue,
  }) {
    return ListBatchesResponse(
      operations: operations == unsetCopyWithValue
          ? this.operations
          : operations as List<Operation>?,
      nextPageToken: nextPageToken == unsetCopyWithValue
          ? this.nextPageToken
          : nextPageToken as String?,
      unreachable: unreachable == unsetCopyWithValue
          ? this.unreachable
          : unreachable as List<String>?,
    );
  }
}
