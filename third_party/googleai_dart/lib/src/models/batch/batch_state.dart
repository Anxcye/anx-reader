/// State of a batch operation.
enum BatchState {
  /// The batch state is unspecified.
  unspecified,

  /// The service is preparing to run the batch.
  pending,

  /// The batch is in progress.
  running,

  /// The batch completed successfully.
  succeeded,

  /// The batch failed.
  failed,

  /// The batch has been cancelled.
  cancelled,

  /// The batch has expired.
  expired,
}

/// Converts a string to a [BatchState].
BatchState batchStateFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'BATCH_STATE_PENDING' => BatchState.pending,
    'BATCH_STATE_RUNNING' => BatchState.running,
    'BATCH_STATE_SUCCEEDED' => BatchState.succeeded,
    'BATCH_STATE_FAILED' => BatchState.failed,
    'BATCH_STATE_CANCELLED' => BatchState.cancelled,
    'BATCH_STATE_EXPIRED' => BatchState.expired,
    _ => BatchState.unspecified,
  };
}

/// Converts a [BatchState] to a string.
String batchStateToString(BatchState state) {
  return switch (state) {
    BatchState.pending => 'BATCH_STATE_PENDING',
    BatchState.running => 'BATCH_STATE_RUNNING',
    BatchState.succeeded => 'BATCH_STATE_SUCCEEDED',
    BatchState.failed => 'BATCH_STATE_FAILED',
    BatchState.cancelled => 'BATCH_STATE_CANCELLED',
    BatchState.expired => 'BATCH_STATE_EXPIRED',
    BatchState.unspecified => 'BATCH_STATE_UNSPECIFIED',
  };
}
