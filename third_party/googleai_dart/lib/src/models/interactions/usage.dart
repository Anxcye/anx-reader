import '../copy_with_sentinel.dart';
import 'modality_tokens.dart';

/// Statistics on the interaction request's token usage.
class InteractionUsage {
  /// Number of tokens in the prompt (context).
  final int? totalInputTokens;

  /// A breakdown of input token usage by modality.
  final List<ModalityTokens>? inputTokensByModality;

  /// Number of tokens in the cached part of the prompt.
  final int? totalCachedTokens;

  /// A breakdown of cached token usage by modality.
  final List<ModalityTokens>? cachedTokensByModality;

  /// Total number of tokens across all generated responses.
  final int? totalOutputTokens;

  /// A breakdown of output token usage by modality.
  final List<ModalityTokens>? outputTokensByModality;

  /// Number of tokens present in tool-use prompts.
  final int? totalToolUseTokens;

  /// A breakdown of tool-use token usage by modality.
  final List<ModalityTokens>? toolUseTokensByModality;

  /// Number of tokens of thoughts for thinking models.
  final int? totalReasoningTokens;

  /// Total token count for the interaction request.
  final int? totalTokens;

  /// Creates an [InteractionUsage] instance.
  const InteractionUsage({
    this.totalInputTokens,
    this.inputTokensByModality,
    this.totalCachedTokens,
    this.cachedTokensByModality,
    this.totalOutputTokens,
    this.outputTokensByModality,
    this.totalToolUseTokens,
    this.toolUseTokensByModality,
    this.totalReasoningTokens,
    this.totalTokens,
  });

  /// Creates an [InteractionUsage] from JSON.
  factory InteractionUsage.fromJson(Map<String, dynamic> json) =>
      InteractionUsage(
        totalInputTokens: json['total_input_tokens'] as int?,
        inputTokensByModality:
            (json['input_tokens_by_modality'] as List<dynamic>?)
                ?.map((e) => ModalityTokens.fromJson(e as Map<String, dynamic>))
                .toList(),
        totalCachedTokens: json['total_cached_tokens'] as int?,
        cachedTokensByModality:
            (json['cached_tokens_by_modality'] as List<dynamic>?)
                ?.map((e) => ModalityTokens.fromJson(e as Map<String, dynamic>))
                .toList(),
        totalOutputTokens: json['total_output_tokens'] as int?,
        outputTokensByModality:
            (json['output_tokens_by_modality'] as List<dynamic>?)
                ?.map((e) => ModalityTokens.fromJson(e as Map<String, dynamic>))
                .toList(),
        totalToolUseTokens: json['total_tool_use_tokens'] as int?,
        toolUseTokensByModality:
            (json['tool_use_tokens_by_modality'] as List<dynamic>?)
                ?.map((e) => ModalityTokens.fromJson(e as Map<String, dynamic>))
                .toList(),
        totalReasoningTokens: json['total_reasoning_tokens'] as int?,
        totalTokens: json['total_tokens'] as int?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (totalInputTokens != null) 'total_input_tokens': totalInputTokens,
    if (inputTokensByModality != null)
      'input_tokens_by_modality': inputTokensByModality!
          .map((e) => e.toJson())
          .toList(),
    if (totalCachedTokens != null) 'total_cached_tokens': totalCachedTokens,
    if (cachedTokensByModality != null)
      'cached_tokens_by_modality': cachedTokensByModality!
          .map((e) => e.toJson())
          .toList(),
    if (totalOutputTokens != null) 'total_output_tokens': totalOutputTokens,
    if (outputTokensByModality != null)
      'output_tokens_by_modality': outputTokensByModality!
          .map((e) => e.toJson())
          .toList(),
    if (totalToolUseTokens != null) 'total_tool_use_tokens': totalToolUseTokens,
    if (toolUseTokensByModality != null)
      'tool_use_tokens_by_modality': toolUseTokensByModality!
          .map((e) => e.toJson())
          .toList(),
    if (totalReasoningTokens != null)
      'total_reasoning_tokens': totalReasoningTokens,
    if (totalTokens != null) 'total_tokens': totalTokens,
  };

  /// Creates a copy with replaced values.
  InteractionUsage copyWith({
    Object? totalInputTokens = unsetCopyWithValue,
    Object? inputTokensByModality = unsetCopyWithValue,
    Object? totalCachedTokens = unsetCopyWithValue,
    Object? cachedTokensByModality = unsetCopyWithValue,
    Object? totalOutputTokens = unsetCopyWithValue,
    Object? outputTokensByModality = unsetCopyWithValue,
    Object? totalToolUseTokens = unsetCopyWithValue,
    Object? toolUseTokensByModality = unsetCopyWithValue,
    Object? totalReasoningTokens = unsetCopyWithValue,
    Object? totalTokens = unsetCopyWithValue,
  }) {
    return InteractionUsage(
      totalInputTokens: totalInputTokens == unsetCopyWithValue
          ? this.totalInputTokens
          : totalInputTokens as int?,
      inputTokensByModality: inputTokensByModality == unsetCopyWithValue
          ? this.inputTokensByModality
          : inputTokensByModality as List<ModalityTokens>?,
      totalCachedTokens: totalCachedTokens == unsetCopyWithValue
          ? this.totalCachedTokens
          : totalCachedTokens as int?,
      cachedTokensByModality: cachedTokensByModality == unsetCopyWithValue
          ? this.cachedTokensByModality
          : cachedTokensByModality as List<ModalityTokens>?,
      totalOutputTokens: totalOutputTokens == unsetCopyWithValue
          ? this.totalOutputTokens
          : totalOutputTokens as int?,
      outputTokensByModality: outputTokensByModality == unsetCopyWithValue
          ? this.outputTokensByModality
          : outputTokensByModality as List<ModalityTokens>?,
      totalToolUseTokens: totalToolUseTokens == unsetCopyWithValue
          ? this.totalToolUseTokens
          : totalToolUseTokens as int?,
      toolUseTokensByModality: toolUseTokensByModality == unsetCopyWithValue
          ? this.toolUseTokensByModality
          : toolUseTokensByModality as List<ModalityTokens>?,
      totalReasoningTokens: totalReasoningTokens == unsetCopyWithValue
          ? this.totalReasoningTokens
          : totalReasoningTokens as int?,
      totalTokens: totalTokens == unsetCopyWithValue
          ? this.totalTokens
          : totalTokens as int?,
    );
  }
}
