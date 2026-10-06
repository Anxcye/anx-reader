part of 'content.dart';

/// A code execution call content block.
class CodeExecutionCallContent extends InteractionContent {
  @override
  String get type => 'code_execution_call';

  /// A unique ID for this specific tool call.
  final String? id;

  /// The programming language of the code.
  final String? language;

  /// The code to execute.
  final String? code;

  /// Creates a [CodeExecutionCallContent] instance.
  const CodeExecutionCallContent({this.id, this.language, this.code});

  /// Creates a [CodeExecutionCallContent] from JSON.
  factory CodeExecutionCallContent.fromJson(Map<String, dynamic> json) {
    final arguments = json['arguments'] as Map<String, dynamic>?;
    return CodeExecutionCallContent(
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

  /// Creates a copy with replaced values.
  CodeExecutionCallContent copyWith({
    Object? id = unsetCopyWithValue,
    Object? language = unsetCopyWithValue,
    Object? code = unsetCopyWithValue,
  }) {
    return CodeExecutionCallContent(
      id: id == unsetCopyWithValue ? this.id : id as String?,
      language: language == unsetCopyWithValue
          ? this.language
          : language as String?,
      code: code == unsetCopyWithValue ? this.code : code as String?,
    );
  }
}
