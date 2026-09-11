import '../content/candidate.dart';
import 'input_feedback.dart';

/// Response from the model for a grounded answer.
class GenerateAnswerResponse {
  /// Candidate answer from the model.
  ///
  /// Note: The model *always* attempts to provide a grounded answer, even
  /// when the answer is unlikely to be answerable from the given passages.
  /// In that case, a low-quality or ungrounded answer may be provided, along
  /// with a low `answerable_probability`.
  final Candidate? answer;

  /// Output only. The model's estimate of the probability that its answer is
  /// correct and grounded in the input passages.
  ///
  /// A low `answerable_probability` indicates that the answer might not be
  /// grounded in the sources.
  ///
  /// When `answerable_probability` is low, you may want to:
  /// - Display a message to the effect of "We couldn't answer that question"
  ///   to the user.
  /// - Fall back to a general-purpose LLM that answers the question from
  ///   world knowledge. The threshold and nature of such fallbacks will
  ///   depend on individual use cases. `0.5` is a good starting threshold.
  final double? answerableProbability;

  /// Output only. Feedback related to the input data used to answer the
  /// question, as opposed to the model-generated response to the question.
  ///
  /// The input data can be one or more of the following:
  /// - Question specified by the last entry in `GenerateAnswerRequest.content`
  /// - Conversation history specified by the other entries in
  ///   `GenerateAnswerRequest.content`
  /// - Grounding sources (`GenerateAnswerRequest.semantic_retriever` or
  ///   `GenerateAnswerRequest.inline_passages`)
  final InputFeedback? inputFeedback;

  /// Creates a [GenerateAnswerResponse].
  const GenerateAnswerResponse({
    this.answer,
    this.answerableProbability,
    this.inputFeedback,
  });

  /// Creates a [GenerateAnswerResponse] from JSON.
  factory GenerateAnswerResponse.fromJson(Map<String, dynamic> json) =>
      GenerateAnswerResponse(
        answer: json['answer'] != null
            ? Candidate.fromJson(json['answer'] as Map<String, dynamic>)
            : null,
        answerableProbability: json['answerableProbability'] as double?,
        inputFeedback: json['inputFeedback'] != null
            ? InputFeedback.fromJson(
                json['inputFeedback'] as Map<String, dynamic>,
              )
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (answer != null) 'answer': answer!.toJson(),
    if (answerableProbability != null)
      'answerableProbability': answerableProbability,
    if (inputFeedback != null) 'inputFeedback': inputFeedback!.toJson(),
  };
}
