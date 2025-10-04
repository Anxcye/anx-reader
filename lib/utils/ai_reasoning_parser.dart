class ParsedReasoning {
  const ParsedReasoning({
    required this.think,
    required this.answer,
  });

  final String think;
  final String answer;

  bool get hasThink => think.trim().isNotEmpty;

  bool get hasAnswer => answer.trim().isNotEmpty;
}

ParsedReasoning parseReasoningContent(String content) {
  if (content.startsWith('<think>') && content.contains('</think>')) {
    final endIndex = content.indexOf('</think>');
    if (endIndex != -1) {
      final think = content.substring('<think>'.length, endIndex);
      final answer = content.substring(endIndex + '</think>'.length);
      return ParsedReasoning(think: think.trim(), answer: answer);
    }
  }

  return ParsedReasoning(think: '', answer: content);
}
