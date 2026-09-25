import '../copy_with_sentinel.dart';
import 'image_config.dart';
import 'thinking_config.dart';

/// Configuration options for model generation.
class GenerationConfig {
  /// Number of generated responses to return.
  final int? candidateCount;

  /// Stop sequences.
  final List<String>? stopSequences;

  /// Maximum number of tokens to generate.
  final int? maxOutputTokens;

  /// Controls randomness (0.0 to 2.0).
  final double? temperature;

  /// Top-p sampling (0.0 to 1.0).
  final double? topP;

  /// Top-k sampling.
  final int? topK;

  /// Presence penalty.
  final double? presencePenalty;

  /// Frequency penalty.
  final double? frequencyPenalty;

  /// Response MIME type.
  final String? responseMimeType;

  /// Response schema (for structured output).
  final Map<String, dynamic>? responseSchema;

  /// Thinking configuration.
  final ThinkingConfig? thinkingConfig;

  /// Image generation configuration.
  final ImageConfig? imageConfig;

  /// Seed used in decoding.
  ///
  /// If not set, the request uses a randomly generated seed.
  final int? seed;

  /// If true, export the logprobs results in response.
  final bool? responseLogprobs;

  /// Number of top logprobs to return at each decoding step.
  ///
  /// Only valid if [responseLogprobs] is true.
  /// The number must be in the range of [0, 20].
  final int? logprobs;

  /// The requested modalities of the response.
  ///
  /// Represents the set of modalities that the model can return.
  /// Supported values: TEXT, IMAGE, AUDIO.
  /// An empty list is equivalent to requesting only text.
  final List<String>? responseModalities;

  /// Media resolution for input media.
  ///
  /// Supported values: MEDIA_RESOLUTION_UNSPECIFIED, MEDIA_RESOLUTION_LOW,
  /// MEDIA_RESOLUTION_MEDIUM, MEDIA_RESOLUTION_HIGH.
  final String? mediaResolution;

  /// Response JSON schema for structured output.
  ///
  /// This is separate from [responseSchema] and provides additional
  /// schema configuration options.
  final Map<String, dynamic>? responseJsonSchema;

  /// Enables enhanced civic answers.
  ///
  /// It may not be available for all models.
  final bool? enableEnhancedCivicAnswers;

  /// The speech generation config.
  ///
  /// Contains voice configuration for speech output including
  /// single-voice and multi-speaker setups.
  final Map<String, dynamic>? speechConfig;

  /// Creates a [GenerationConfig].
  const GenerationConfig({
    this.candidateCount,
    this.stopSequences,
    this.maxOutputTokens,
    this.temperature,
    this.topP,
    this.topK,
    this.presencePenalty,
    this.frequencyPenalty,
    this.responseMimeType,
    this.responseSchema,
    this.thinkingConfig,
    this.imageConfig,
    this.seed,
    this.responseLogprobs,
    this.logprobs,
    this.responseModalities,
    this.mediaResolution,
    this.responseJsonSchema,
    this.enableEnhancedCivicAnswers,
    this.speechConfig,
  });

  /// Creates a [GenerationConfig] from JSON.
  factory GenerationConfig.fromJson(Map<String, dynamic> json) =>
      GenerationConfig(
        candidateCount: json['candidateCount'] as int?,
        stopSequences: (json['stopSequences'] as List?)?.cast<String>(),
        maxOutputTokens: json['maxOutputTokens'] as int?,
        temperature: (json['temperature'] as num?)?.toDouble(),
        topP: (json['topP'] as num?)?.toDouble(),
        topK: json['topK'] as int?,
        presencePenalty: (json['presencePenalty'] as num?)?.toDouble(),
        frequencyPenalty: (json['frequencyPenalty'] as num?)?.toDouble(),
        responseMimeType: json['responseMimeType'] as String?,
        responseSchema: json['responseSchema'] as Map<String, dynamic>?,
        thinkingConfig: json['thinkingConfig'] != null
            ? ThinkingConfig.fromJson(
                json['thinkingConfig'] as Map<String, dynamic>,
              )
            : null,
        imageConfig: json['imageConfig'] != null
            ? ImageConfig.fromJson(json['imageConfig'] as Map<String, dynamic>)
            : null,
        seed: json['seed'] as int?,
        responseLogprobs: json['responseLogprobs'] as bool?,
        logprobs: json['logprobs'] as int?,
        responseModalities: (json['responseModalities'] as List?)
            ?.cast<String>(),
        mediaResolution: json['mediaResolution'] as String?,
        responseJsonSchema: json['responseJsonSchema'] as Map<String, dynamic>?,
        enableEnhancedCivicAnswers: json['enableEnhancedCivicAnswers'] as bool?,
        speechConfig: json['speechConfig'] as Map<String, dynamic>?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (candidateCount != null) 'candidateCount': candidateCount,
    if (stopSequences != null) 'stopSequences': stopSequences,
    if (maxOutputTokens != null) 'maxOutputTokens': maxOutputTokens,
    if (temperature != null) 'temperature': temperature,
    if (topP != null) 'topP': topP,
    if (topK != null) 'topK': topK,
    if (presencePenalty != null) 'presencePenalty': presencePenalty,
    if (frequencyPenalty != null) 'frequencyPenalty': frequencyPenalty,
    if (responseMimeType != null) 'responseMimeType': responseMimeType,
    if (responseSchema != null) 'responseSchema': responseSchema,
    if (thinkingConfig != null) 'thinkingConfig': thinkingConfig!.toJson(),
    if (imageConfig != null) 'imageConfig': imageConfig!.toJson(),
    if (seed != null) 'seed': seed,
    if (responseLogprobs != null) 'responseLogprobs': responseLogprobs,
    if (logprobs != null) 'logprobs': logprobs,
    if (responseModalities != null) 'responseModalities': responseModalities,
    if (mediaResolution != null) 'mediaResolution': mediaResolution,
    if (responseJsonSchema != null) 'responseJsonSchema': responseJsonSchema,
    if (enableEnhancedCivicAnswers != null)
      'enableEnhancedCivicAnswers': enableEnhancedCivicAnswers,
    if (speechConfig != null) 'speechConfig': speechConfig,
  };

  /// Creates a copy with replaced values.
  GenerationConfig copyWith({
    Object? candidateCount = unsetCopyWithValue,
    Object? stopSequences = unsetCopyWithValue,
    Object? maxOutputTokens = unsetCopyWithValue,
    Object? temperature = unsetCopyWithValue,
    Object? topP = unsetCopyWithValue,
    Object? topK = unsetCopyWithValue,
    Object? presencePenalty = unsetCopyWithValue,
    Object? frequencyPenalty = unsetCopyWithValue,
    Object? responseMimeType = unsetCopyWithValue,
    Object? responseSchema = unsetCopyWithValue,
    Object? thinkingConfig = unsetCopyWithValue,
    Object? imageConfig = unsetCopyWithValue,
    Object? seed = unsetCopyWithValue,
    Object? responseLogprobs = unsetCopyWithValue,
    Object? logprobs = unsetCopyWithValue,
    Object? responseModalities = unsetCopyWithValue,
    Object? mediaResolution = unsetCopyWithValue,
    Object? responseJsonSchema = unsetCopyWithValue,
    Object? enableEnhancedCivicAnswers = unsetCopyWithValue,
    Object? speechConfig = unsetCopyWithValue,
  }) {
    return GenerationConfig(
      candidateCount: candidateCount == unsetCopyWithValue
          ? this.candidateCount
          : candidateCount as int?,
      stopSequences: stopSequences == unsetCopyWithValue
          ? this.stopSequences
          : stopSequences as List<String>?,
      maxOutputTokens: maxOutputTokens == unsetCopyWithValue
          ? this.maxOutputTokens
          : maxOutputTokens as int?,
      temperature: temperature == unsetCopyWithValue
          ? this.temperature
          : temperature as double?,
      topP: topP == unsetCopyWithValue ? this.topP : topP as double?,
      topK: topK == unsetCopyWithValue ? this.topK : topK as int?,
      presencePenalty: presencePenalty == unsetCopyWithValue
          ? this.presencePenalty
          : presencePenalty as double?,
      frequencyPenalty: frequencyPenalty == unsetCopyWithValue
          ? this.frequencyPenalty
          : frequencyPenalty as double?,
      responseMimeType: responseMimeType == unsetCopyWithValue
          ? this.responseMimeType
          : responseMimeType as String?,
      responseSchema: responseSchema == unsetCopyWithValue
          ? this.responseSchema
          : responseSchema as Map<String, dynamic>?,
      thinkingConfig: thinkingConfig == unsetCopyWithValue
          ? this.thinkingConfig
          : thinkingConfig as ThinkingConfig?,
      imageConfig: imageConfig == unsetCopyWithValue
          ? this.imageConfig
          : imageConfig as ImageConfig?,
      seed: seed == unsetCopyWithValue ? this.seed : seed as int?,
      responseLogprobs: responseLogprobs == unsetCopyWithValue
          ? this.responseLogprobs
          : responseLogprobs as bool?,
      logprobs: logprobs == unsetCopyWithValue
          ? this.logprobs
          : logprobs as int?,
      responseModalities: responseModalities == unsetCopyWithValue
          ? this.responseModalities
          : responseModalities as List<String>?,
      mediaResolution: mediaResolution == unsetCopyWithValue
          ? this.mediaResolution
          : mediaResolution as String?,
      responseJsonSchema: responseJsonSchema == unsetCopyWithValue
          ? this.responseJsonSchema
          : responseJsonSchema as Map<String, dynamic>?,
      enableEnhancedCivicAnswers:
          enableEnhancedCivicAnswers == unsetCopyWithValue
          ? this.enableEnhancedCivicAnswers
          : enableEnhancedCivicAnswers as bool?,
      speechConfig: speechConfig == unsetCopyWithValue
          ? this.speechConfig
          : speechConfig as Map<String, dynamic>?,
    );
  }
}
