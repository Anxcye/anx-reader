import '../copy_with_sentinel.dart';

/// Outcome of the code execution.
enum Outcome {
  /// Unspecified outcome.
  unspecified,

  /// Code execution completed successfully.
  ok,

  /// Code execution encountered a fatal error.
  failed,

  /// Code execution exceeded the deadline.
  deadlineExceeded,
}

/// Result of executing the ExecutableCode.
class CodeExecutionResult {
  /// Outcome of the code execution.
  final Outcome outcome;

  /// Contains stdout when code execution is successful, stderr or other
  /// description otherwise.
  final String output;

  /// Creates a [CodeExecutionResult].
  const CodeExecutionResult({required this.outcome, required this.output});

  /// Creates a [CodeExecutionResult] from JSON.
  factory CodeExecutionResult.fromJson(Map<String, dynamic> json) =>
      CodeExecutionResult(
        outcome: _outcomeFromString(json['outcome'] as String?),
        output: json['output'] as String,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'outcome': _outcomeToString(outcome),
    'output': output,
  };

  /// Creates a copy with replaced values.
  CodeExecutionResult copyWith({
    Object? outcome = unsetCopyWithValue,
    Object? output = unsetCopyWithValue,
  }) {
    return CodeExecutionResult(
      outcome: outcome == unsetCopyWithValue
          ? this.outcome
          : outcome! as Outcome,
      output: output == unsetCopyWithValue ? this.output : output! as String,
    );
  }
}

/// Converts string to Outcome enum.
Outcome _outcomeFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'OUTCOME_OK' => Outcome.ok,
    'OUTCOME_FAILED' => Outcome.failed,
    'OUTCOME_DEADLINE_EXCEEDED' => Outcome.deadlineExceeded,
    _ => Outcome.unspecified,
  };
}

/// Converts Outcome enum to string.
String _outcomeToString(Outcome outcome) {
  return switch (outcome) {
    Outcome.ok => 'OUTCOME_OK',
    Outcome.failed => 'OUTCOME_FAILED',
    Outcome.deadlineExceeded => 'OUTCOME_DEADLINE_EXCEEDED',
    Outcome.unspecified => 'OUTCOME_UNSPECIFIED',
  };
}
