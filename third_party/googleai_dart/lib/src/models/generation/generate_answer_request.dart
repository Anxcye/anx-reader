import '../content/content.dart';
import '../safety/safety_setting.dart';
import 'answer_style.dart';
import 'grounding_passages.dart';

/// Request to generate a grounded answer from the `Model`.
class GenerateAnswerRequest {
  /// Required. The content of the current conversation with the `Model`.
  /// For single-turn queries, this is a single question to answer.
  /// For multi-turn queries, this is a repeated field that contains
  /// conversation history and the last `Content` in the list containing
  /// the question.
  ///
  /// Note: `GenerateAnswer` only supports queries in English.
  final List<Content> contents;

  /// Required. Style in which answers should be returned.
  final AnswerStyle answerStyle;

  /// Passages provided inline with the request.
  final GroundingPassages? inlinePassages;

  /// Optional. A list of unique `SafetySetting` instances for blocking
  /// unsafe content.
  ///
  /// This will be enforced on the `GenerateAnswerRequest.contents` and
  /// `GenerateAnswerResponse.candidate`. There should not be more than one
  /// setting for each `SafetyCategory` type. The API will block any contents
  /// and responses that fail to meet the thresholds set by these settings.
  /// This list overrides the default settings for each `SafetyCategory`
  /// specified in the safety_settings. If there is no `SafetySetting` for a
  /// given `SafetyCategory` provided in the list, the API will use the
  /// default safety setting for that category.
  final List<SafetySetting>? safetySettings;

  /// Optional. Controls the randomness of the output.
  ///
  /// Values can range from [0.0,1.0], inclusive. A value closer to 1.0 will
  /// produce responses that are more varied and creative, while a value
  /// closer to 0.0 will typically result in more straightforward responses
  /// from the model. A low temperature (~0.2) is usually recommended for
  /// Attributed-Question-Answering use cases.
  final double? temperature;

  /// Creates a [GenerateAnswerRequest].
  const GenerateAnswerRequest({
    required this.contents,
    required this.answerStyle,
    this.inlinePassages,
    this.safetySettings,
    this.temperature,
  });

  /// Creates a [GenerateAnswerRequest] from JSON.
  factory GenerateAnswerRequest.fromJson(Map<String, dynamic> json) =>
      GenerateAnswerRequest(
        contents: ((json['contents'] as List?) ?? [])
            .map((e) => Content.fromJson(e as Map<String, dynamic>))
            .toList(),
        answerStyle: answerStyleFromString(json['answerStyle'] as String?),
        inlinePassages: json['inlinePassages'] != null
            ? GroundingPassages.fromJson(
                json['inlinePassages'] as Map<String, dynamic>,
              )
            : null,
        safetySettings: json['safetySettings'] != null
            ? (json['safetySettings'] as List)
                  .map((e) => SafetySetting.fromJson(e as Map<String, dynamic>))
                  .toList()
            : null,
        temperature: json['temperature'] as double?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'contents': contents.map((e) => e.toJson()).toList(),
    'answerStyle': answerStyleToString(answerStyle),
    if (inlinePassages != null) 'inlinePassages': inlinePassages!.toJson(),
    if (safetySettings != null)
      'safetySettings': safetySettings!.map((e) => e.toJson()).toList(),
    if (temperature != null) 'temperature': temperature,
  };
}
