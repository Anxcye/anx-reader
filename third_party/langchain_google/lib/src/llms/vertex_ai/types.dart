import 'package:collection/collection.dart';
import 'package:langchain_core/llms.dart';
import 'package:meta/meta.dart';

/// {@template vertex_ai_options}
/// Options to pass into the Vertex AI LLM (Gemini API).
///
/// You can find a list of available models here:
/// https://cloud.google.com/vertex-ai/generative-ai/docs/learn/model-versions#latest-stable
/// {@endtemplate}
@immutable
class VertexAIOptions extends LLMOptions {
  /// {@macro vertex_ai_options}
  const VertexAIOptions({
    super.model,
    this.maxOutputTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.stopSequences,
    this.candidateCount,
    super.concurrencyLimit,
  });

  /// Maximum number of tokens that can be generated in the response.
  ///
  /// If unset, this will default to `output_token_limit` specified in the `Model`
  /// specification.
  final int? maxOutputTokens;

  /// Controls the randomness of the output.
  ///
  /// Note: The default value varies by model, see the `Model.temperature`
  /// attribute of the `Model` returned the `getModel` function.
  ///
  /// Values can range from [0.0,1.0], inclusive. A value closer to 1.0 will
  /// produce responses that are more varied and creative, while a value
  /// closer to 0.0 will typically result in more straightforward responses
  /// from the model.
  final double? temperature;

  /// The maximum cumulative probability of tokens to consider when sampling.
  ///
  /// The model uses combined Top-k and nucleus sampling. Tokens are sorted
  /// based on their assigned probabilities so that only the most likely
  /// tokens are considered. Top-k sampling directly limits the maximum
  /// number of tokens to consider, while Nucleus sampling limits number of
  /// tokens based on the cumulative probability.
  ///
  /// Note: The default value varies by model, see the `Model.top_p`
  /// attribute of the `Model` returned the `getModel` function.
  final double? topP;

  /// The maximum number of tokens to consider when sampling.
  ///
  /// The model uses combined Top-k and nucleus sampling. Top-k sampling considers
  /// the set of `top_k` most probable tokens. Defaults to 40.
  ///
  /// Note: The default value varies by model, see the `Model.top_k` attribute
  /// of the `Model` returned the `getModel` function.
  final int? topK;

  /// The set of character sequences (up to 5) that will stop output generation.
  ///
  /// If specified, the API will stop at the first appearance of a stop sequence.
  /// The stop sequence will not be included as part of the response.
  final List<String>? stopSequences;

  /// Number of generated responses to return.
  ///
  /// This value must be between [1, 8], inclusive. If unset, this will default to 1.
  final int? candidateCount;

  @override
  VertexAIOptions copyWith({
    final String? model,
    final int? maxOutputTokens,
    final double? temperature,
    final double? topP,
    final int? topK,
    final List<String>? stopSequences,
    final int? candidateCount,
    final int? concurrencyLimit,
  }) {
    return VertexAIOptions(
      model: model ?? this.model,
      maxOutputTokens: maxOutputTokens ?? this.maxOutputTokens,
      temperature: temperature ?? this.temperature,
      topP: topP ?? this.topP,
      topK: topK ?? this.topK,
      stopSequences: stopSequences ?? this.stopSequences,
      candidateCount: candidateCount ?? this.candidateCount,
      concurrencyLimit: concurrencyLimit ?? this.concurrencyLimit,
    );
  }

  @override
  VertexAIOptions merge(covariant final VertexAIOptions? other) {
    return copyWith(
      model: other?.model,
      maxOutputTokens: other?.maxOutputTokens,
      temperature: other?.temperature,
      topP: other?.topP,
      topK: other?.topK,
      stopSequences: other?.stopSequences,
      candidateCount: other?.candidateCount,
      concurrencyLimit: other?.concurrencyLimit,
    );
  }

  @override
  bool operator ==(covariant final VertexAIOptions other) {
    return model == other.model &&
        maxOutputTokens == other.maxOutputTokens &&
        temperature == other.temperature &&
        topP == other.topP &&
        topK == other.topK &&
        const ListEquality<String>().equals(
          stopSequences,
          other.stopSequences,
        ) &&
        candidateCount == other.candidateCount &&
        concurrencyLimit == other.concurrencyLimit;
  }

  @override
  int get hashCode {
    return model.hashCode ^
        maxOutputTokens.hashCode ^
        temperature.hashCode ^
        topP.hashCode ^
        topK.hashCode ^
        const ListEquality<String>().hash(stopSequences) ^
        candidateCount.hashCode ^
        concurrencyLimit.hashCode;
  }
}
