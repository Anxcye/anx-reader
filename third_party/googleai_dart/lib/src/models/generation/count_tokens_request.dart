import '../content/content.dart';
import '../copy_with_sentinel.dart';
import 'generate_content_request.dart';

/// Request to count tokens.
class CountTokensRequest {
  /// The content to count tokens for.
  /// This field is ignored when [generateContentRequest] is set.
  final List<Content>? contents;

  /// The overall input given to the model.
  /// This includes the prompt as well as other model steering information
  /// like system instructions and/or function declarations.
  /// [contents] and [generateContentRequest] are mutually exclusive.
  final GenerateContentRequest? generateContentRequest;

  /// System instruction for the model (Vertex AI).
  /// Used when counting tokens for Vertex AI API.
  final Content? systemInstruction;

  /// Creates a [CountTokensRequest].
  const CountTokensRequest({
    this.contents,
    this.generateContentRequest,
    this.systemInstruction,
  });

  /// Creates a [CountTokensRequest] from JSON.
  factory CountTokensRequest.fromJson(Map<String, dynamic> json) =>
      CountTokensRequest(
        contents: json['contents'] != null
            ? (json['contents'] as List)
                  .map((e) => Content.fromJson(e as Map<String, dynamic>))
                  .toList()
            : null,
        generateContentRequest: json['generateContentRequest'] != null
            ? GenerateContentRequest.fromJson(
                json['generateContentRequest'] as Map<String, dynamic>,
              )
            : null,
        systemInstruction: json['system_instruction'] != null
            ? Content.fromJson(
                json['system_instruction'] as Map<String, dynamic>,
              )
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (contents != null) 'contents': contents!.map((e) => e.toJson()).toList(),
    if (generateContentRequest != null)
      'generateContentRequest': generateContentRequest!.toJson(),
    if (systemInstruction != null)
      'system_instruction': systemInstruction!.toJson(),
  };

  /// Creates a copy with replaced values.
  CountTokensRequest copyWith({
    Object? contents = unsetCopyWithValue,
    Object? generateContentRequest = unsetCopyWithValue,
    Object? systemInstruction = unsetCopyWithValue,
  }) {
    return CountTokensRequest(
      contents: contents == unsetCopyWithValue
          ? this.contents
          : contents as List<Content>?,
      generateContentRequest: generateContentRequest == unsetCopyWithValue
          ? this.generateContentRequest
          : generateContentRequest as GenerateContentRequest?,
      systemInstruction: systemInstruction == unsetCopyWithValue
          ? this.systemInstruction
          : systemInstruction as Content?,
    );
  }
}
