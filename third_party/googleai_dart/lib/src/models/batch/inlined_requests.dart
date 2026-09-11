import '../copy_with_sentinel.dart';
import 'inlined_request.dart';

/// A list of inlined requests for batch processing.
class InlinedRequests {
  /// The requests to be processed in the batch.
  final List<InlinedRequest> requests;

  /// Creates an [InlinedRequests].
  const InlinedRequests({required this.requests});

  /// Creates an [InlinedRequests] from JSON.
  factory InlinedRequests.fromJson(Map<String, dynamic> json) =>
      InlinedRequests(
        requests: ((json['requests'] as List?) ?? [])
            .map((e) => InlinedRequest.fromJson(e as Map<String, dynamic>))
            .toList(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'requests': requests.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  InlinedRequests copyWith({Object? requests = unsetCopyWithValue}) {
    return InlinedRequests(
      requests: requests == unsetCopyWithValue
          ? this.requests
          : requests! as List<InlinedRequest>,
    );
  }
}
