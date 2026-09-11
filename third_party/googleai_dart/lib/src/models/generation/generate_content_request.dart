import '../content/content.dart';
import '../copy_with_sentinel.dart';
import '../safety/safety_setting.dart';
import '../tools/tool.dart';
import 'generation_config.dart';

/// Request to generate content.
class GenerateContentRequest {
  /// The content to send to the model.
  final List<Content> contents;

  /// Optional list of tools the model may use.
  final List<Tool>? tools;

  /// Tool configuration.
  final Map<String, dynamic>? toolConfig;

  /// Safety settings.
  final List<SafetySetting>? safetySettings;

  /// System instruction.
  final Content? systemInstruction;

  /// Generation configuration.
  final GenerationConfig? generationConfig;

  /// Cached content name.
  final String? cachedContent;

  /// Creates a [GenerateContentRequest].
  const GenerateContentRequest({
    required this.contents,
    this.tools,
    this.toolConfig,
    this.safetySettings,
    this.systemInstruction,
    this.generationConfig,
    this.cachedContent,
  });

  /// Creates a [GenerateContentRequest] from JSON.
  factory GenerateContentRequest.fromJson(Map<String, dynamic> json) =>
      GenerateContentRequest(
        contents: ((json['contents'] as List?) ?? [])
            .map((e) => Content.fromJson(e as Map<String, dynamic>))
            .toList(),
        tools: json['tools'] != null
            ? (json['tools'] as List)
                  .map((e) => Tool.fromJson(e as Map<String, dynamic>))
                  .toList()
            : null,
        toolConfig: json['toolConfig'] as Map<String, dynamic>?,
        safetySettings: json['safetySettings'] != null
            ? (json['safetySettings'] as List)
                  .map((e) => SafetySetting.fromJson(e as Map<String, dynamic>))
                  .toList()
            : null,
        systemInstruction: json['systemInstruction'] != null
            ? Content.fromJson(
                json['systemInstruction'] as Map<String, dynamic>,
              )
            : null,
        generationConfig: json['generationConfig'] != null
            ? GenerationConfig.fromJson(
                json['generationConfig'] as Map<String, dynamic>,
              )
            : null,
        cachedContent: json['cachedContent'] as String?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'contents': contents.map((e) => e.toJson()).toList(),
    if (tools != null) 'tools': tools!.map((e) => e.toJson()).toList(),
    if (toolConfig != null) 'toolConfig': toolConfig,
    if (safetySettings != null)
      'safetySettings': safetySettings!.map((e) => e.toJson()).toList(),
    if (systemInstruction != null)
      'systemInstruction': systemInstruction!.toJson(),
    if (generationConfig != null)
      'generationConfig': generationConfig!.toJson(),
    if (cachedContent != null) 'cachedContent': cachedContent,
  };

  /// Creates a copy with replaced values.
  GenerateContentRequest copyWith({
    Object? contents = unsetCopyWithValue,
    Object? tools = unsetCopyWithValue,
    Object? toolConfig = unsetCopyWithValue,
    Object? safetySettings = unsetCopyWithValue,
    Object? systemInstruction = unsetCopyWithValue,
    Object? generationConfig = unsetCopyWithValue,
    Object? cachedContent = unsetCopyWithValue,
  }) {
    return GenerateContentRequest(
      contents: contents == unsetCopyWithValue
          ? this.contents
          : contents! as List<Content>,
      tools: tools == unsetCopyWithValue ? this.tools : tools as List<Tool>?,
      toolConfig: toolConfig == unsetCopyWithValue
          ? this.toolConfig
          : toolConfig as Map<String, dynamic>?,
      safetySettings: safetySettings == unsetCopyWithValue
          ? this.safetySettings
          : safetySettings as List<SafetySetting>?,
      systemInstruction: systemInstruction == unsetCopyWithValue
          ? this.systemInstruction
          : systemInstruction as Content?,
      generationConfig: generationConfig == unsetCopyWithValue
          ? this.generationConfig
          : generationConfig as GenerationConfig?,
      cachedContent: cachedContent == unsetCopyWithValue
          ? this.cachedContent
          : cachedContent as String?,
    );
  }
}
