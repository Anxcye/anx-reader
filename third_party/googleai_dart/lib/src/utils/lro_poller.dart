import '../client/googleai_client.dart';
import '../errors/exceptions.dart';
import '../models/models/operation.dart';

/// Poller for long-running operations (LRO).
///
/// Some operations (like creating tuned models) are asynchronous and return
/// an [Operation] object. This utility polls the operation until it completes
/// or fails.
///
/// Example:
/// ```dart
/// final operation = await client.createTunedModel(...);
/// final poller = LROPoller(
///   client: client,
///   operationName: operation.name!,
///   deserializer: TunedModel.fromJson,
/// );
/// final result = await poller.poll();
/// ```
class LROPoller<T> {
  /// The client to use for polling.
  final GoogleAIClient client;

  /// The operation name to poll (e.g., "operations/abc123").
  final String operationName;

  /// Function to deserialize the result from JSON.
  final T Function(Map<String, dynamic>) deserializer;

  /// Interval between poll attempts.
  final Duration pollInterval;

  /// Maximum time to wait for completion.
  final Duration? timeout;

  /// Creates an [LROPoller].
  const LROPoller({
    required this.client,
    required this.operationName,
    required this.deserializer,
    this.pollInterval = const Duration(seconds: 5),
    this.timeout = const Duration(minutes: 30),
  });

  /// Polls the operation until it completes.
  ///
  /// Returns the deserialized result when the operation succeeds.
  ///
  /// Throws an [ApiException] if the operation fails.
  /// Throws a [TimeoutException] if polling times out.
  Future<T> poll() async {
    final startTime = DateTime.now();

    while (true) {
      final operation = await client.getOperation(name: operationName);

      if (operation.done) {
        // Operation completed
        if (operation.error != null) {
          // Operation failed
          throw ApiException(
            code: operation.error!.code,
            message: operation.error!.message,
            details: operation.error!.details?.cast<Object>() ?? [],
          );
        }

        // Operation succeeded
        if (operation.response == null) {
          throw const ApiException(
            code: 500,
            message: 'Operation completed but response is null',
          );
        }

        return deserializer(operation.response!);
      }

      // Check timeout
      if (timeout != null) {
        final elapsed = DateTime.now().difference(startTime);
        if (elapsed > timeout!) {
          throw TimeoutException(
            message: 'Operation polling timed out after ${timeout!.inSeconds}s',
            timeout: timeout!,
            elapsed: elapsed,
          );
        }
      }

      // Wait before next poll
      await Future<void>.delayed(pollInterval);
    }
  }
}
