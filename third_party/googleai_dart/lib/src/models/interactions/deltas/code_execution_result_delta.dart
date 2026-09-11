part of 'deltas.dart';

/// A code execution result delta update.
class CodeExecutionResultDelta extends InteractionDelta {
  @override
  String get type => 'code_execution_result';

  /// ID to match the ID from the code execution call.
  final String? callId;

  /// The output of the code execution.
  final String? result;

  /// Whether the code execution resulted in an error.
  final bool? isError;

  /// A signature hash for backend validation.
  final String? signature;

  /// Creates a [CodeExecutionResultDelta] instance.
  const CodeExecutionResultDelta({
    this.callId,
    this.result,
    this.isError,
    this.signature,
  });

  /// Creates a [CodeExecutionResultDelta] from JSON.
  factory CodeExecutionResultDelta.fromJson(Map<String, dynamic> json) =>
      CodeExecutionResultDelta(
        callId: json['call_id'] as String?,
        result: json['result'] as String?,
        isError: json['is_error'] as bool?,
        signature: json['signature'] as String?,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (callId != null) 'call_id': callId,
    if (result != null) 'result': result,
    if (isError != null) 'is_error': isError,
    if (signature != null) 'signature': signature,
  };
}
