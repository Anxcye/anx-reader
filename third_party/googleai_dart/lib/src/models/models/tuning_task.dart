import '../copy_with_sentinel.dart';

/// Record of a tuning task.
class TuningTask {
  /// The timestamp when tuning started.
  final DateTime? startTime;

  /// The timestamp when tuning completed.
  final DateTime? completeTime;

  /// Number of tuning steps completed.
  final int? snapshots;

  /// Hyperparameters used for tuning.
  final Map<String, dynamic>? hyperparameters;

  /// Creates a [TuningTask].
  const TuningTask({
    this.startTime,
    this.completeTime,
    this.snapshots,
    this.hyperparameters,
  });

  /// Creates a [TuningTask] from JSON.
  factory TuningTask.fromJson(Map<String, dynamic> json) => TuningTask(
    startTime: json['startTime'] != null
        ? DateTime.parse(json['startTime'] as String)
        : null,
    completeTime: json['completeTime'] != null
        ? DateTime.parse(json['completeTime'] as String)
        : null,
    snapshots: json['snapshots'] as int?,
    hyperparameters: json['hyperparameters'] as Map<String, dynamic>?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (startTime != null) 'startTime': startTime!.toIso8601String(),
    if (completeTime != null) 'completeTime': completeTime!.toIso8601String(),
    if (snapshots != null) 'snapshots': snapshots,
    if (hyperparameters != null) 'hyperparameters': hyperparameters,
  };

  /// Creates a copy with replaced values.
  TuningTask copyWith({
    Object? startTime = unsetCopyWithValue,
    Object? completeTime = unsetCopyWithValue,
    Object? snapshots = unsetCopyWithValue,
    Object? hyperparameters = unsetCopyWithValue,
  }) {
    return TuningTask(
      startTime: startTime == unsetCopyWithValue
          ? this.startTime
          : startTime as DateTime?,
      completeTime: completeTime == unsetCopyWithValue
          ? this.completeTime
          : completeTime as DateTime?,
      snapshots: snapshots == unsetCopyWithValue
          ? this.snapshots
          : snapshots as int?,
      hyperparameters: hyperparameters == unsetCopyWithValue
          ? this.hyperparameters
          : hyperparameters as Map<String, dynamic>?,
    );
  }
}
