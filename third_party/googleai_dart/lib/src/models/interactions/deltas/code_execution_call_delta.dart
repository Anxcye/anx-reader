part of 'deltas.dart';

/// A code execution call delta update.
class CodeExecutionCallDelta extends InteractionDelta {
  @override
  String get type => 'code_execution_call';

  /// A unique ID for this specific tool call.
  final String? id;

  /// The programming language of the code.
  final String? language;

  /// The code to execute.
  final String? code;

  /// Creates a [CodeExecutionCallDelta] instance.
  const CodeExecutionCallDelta({this.id, this.language, this.code});

  /// Creates a [CodeExecutionCallDelta] from JSON.
  factory CodeExecutionCallDelta.fromJson(Map<String, dynamic> json) {
    final arguments = json['arguments'] as Map<String, dynamic>?;
    return CodeExecutionCallDelta(
      id: json['id'] as String?,
      language: arguments?['language'] as String?,
      code: arguments?['code'] as String?,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (id != null) 'id': id,
    if (language != null || code != null)
      'arguments': {
        if (language != null) 'language': language,
        if (code != null) 'code': code,
      },
  };
}
