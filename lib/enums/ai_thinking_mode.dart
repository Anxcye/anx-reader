enum AiThinkingMode {
  auto('auto'),
  enabled('enabled'),
  disabled('disabled');

  const AiThinkingMode(this.code);

  final String code;

  static AiThinkingMode fromCode(String? code) {
    return AiThinkingMode.values.firstWhere(
      (value) => value.code == code,
      orElse: () => AiThinkingMode.auto,
    );
  }
}
