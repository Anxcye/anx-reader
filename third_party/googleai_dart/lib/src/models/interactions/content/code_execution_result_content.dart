part of 'content.dart';

/// A code execution result content block.
class CodeExecutionResultContent extends InteractionContent {
  @override
  String get type => 'code_execution_result';

  /// ID to match the ID from the code execution call block.
  final String? callId;

  /// The output of the code execution.
  final String? result;

  /// Whether the code execution resulted in an error.
  final bool? isError;

  /// A signature hash for backend validation.
  final String? signature;

  /// Creates a [CodeExecutionResultContent] instance.
  const CodeExecutionResultContent({
    this.callId,
    this.result,
    this.isError,
    this.signature,
  });

  /// Creates a [CodeExecutionResultContent] from JSON.
  factory CodeExecutionResultContent.fromJson(Map<String, dynamic> json) =>
      CodeExecutionResultContent(
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

  /// Creates a copy with replaced values.
  CodeExecutionResultContent copyWith({
    Object? callId = unsetCopyWithValue,
    Object? result = unsetCopyWithValue,
    Object? isError = unsetCopyWithValue,
    Object? signature = unsetCopyWithValue,
  }) {
    return CodeExecutionResultContent(
      callId: callId == unsetCopyWithValue ? this.callId : callId as String?,
      result: result == unsetCopyWithValue ? this.result : result as String?,
      isError: isError == unsetCopyWithValue ? this.isError : isError as bool?,
      signature: signature == unsetCopyWithValue
          ? this.signature
          : signature as String?,
    );
  }
}
