/// The request format used to control model reasoning.
///
/// Different providers / APIs expose different parameters to enable,
/// disable or tune reasoning (e.g. OpenAI's top-level `reasoning_effort`,
/// DeepSeek's `thinking.type`, Claude's `thinking`, Gemini's
/// `thinkingConfig`). This enum lets the user pick which format the request
/// should follow. `auto` means no reasoning-related parameter is sent at all,
/// letting the model decide by itself (legacy default behavior).
enum AiReasoningFormat {
  /// Do not send any reasoning parameter (model decides by default).
  auto('auto'),

  /// Top-level `reasoning_effort`: `none` / `low` / `medium` / `high`
  /// (OpenAI official and OpenAI-compatible APIs).
  openai('openai'),

  /// Top-level `thinking.type` (enabled/disabled) plus `reasoning_effort`
  /// (DeepSeek `extra_body` style).
  deepseek('deepseek'),

  /// Top-level `thinking` with `type` and `budget_tokens` (Anthropic
  /// extended thinking).
  claude('claude'),

  /// `generationConfig.thinkingConfig.thinkingBudget` (Google Gemini).
  gemini('gemini');

  const AiReasoningFormat(this.code);

  final String code;

  static AiReasoningFormat fromCode(String? code) {
    return AiReasoningFormat.values.firstWhere(
      (value) => value.code == code,
      orElse: () => AiReasoningFormat.auto,
    );
  }
}
