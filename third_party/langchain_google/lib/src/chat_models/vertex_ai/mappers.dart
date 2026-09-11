// ignore_for_file: public_member_api_docs
import 'dart:convert';

import 'package:googleai_dart/googleai_dart.dart' as g;
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/language_models.dart';
import 'package:langchain_core/tools.dart';

import 'types.dart';

extension ChatMessagesMapper on List<ChatMessage> {
  List<g.Content> toContentList() {
    final result = <g.Content>[];

    // NOTE: Gemini can return multiple FunctionCall parts in a single model turn.
    // The API requires the next turn to be ONE Content.functionResponses that
    // includes the SAME number of FunctionResponse parts, in the SAME order.
    // If we send each ToolChatMessage separately, the counts won't match and
    // the API throws an error.
    // Therefore we batch consecutive ToolChatMessage instances into a single
    // Content with multiple FunctionResponseParts.
    List<g.FunctionResponsePart>? pendingToolResponses;

    void flushToolResponses() {
      if (pendingToolResponses != null && pendingToolResponses!.isNotEmpty) {
        result.add(g.Content(role: 'user', parts: pendingToolResponses!));
        pendingToolResponses = null;
      }
    }

    for (final message in this) {
      if (message is SystemChatMessage) {
        continue; // System messages are handled separately
      }

      if (message is ToolChatMessage) {
        // Start (or continue) a batch of tool responses
        pendingToolResponses ??= <g.FunctionResponsePart>[];
        pendingToolResponses!.add(_toolMsgToFunctionResponsePart(message));
        continue;
      }

      // Any non-tool message breaks the batch: flush before adding it
      flushToolResponses();

      switch (message) {
        case final HumanChatMessage msg:
          result.add(_mapHumanChatMessage(msg));
        case final AIChatMessage msg:
          result.add(_mapAIChatMessage(msg));
        case final CustomChatMessage msg:
          result.add(_mapCustomChatMessage(msg));
        default:
          throw UnsupportedError('Unknown message type: $message');
      }
    }

    // Flush remaining batched tool responses at the end
    flushToolResponses();

    return result;
  }

  g.Content _mapHumanChatMessage(final HumanChatMessage msg) {
    final contentParts = switch (msg.content) {
      final ChatMessageContentText c => [g.TextPart(c.text)],
      final ChatMessageContentImage c => [
        if (c.data.startsWith('http'))
          g.FileDataPart(g.FileData(fileUri: c.data))
        else
          g.InlineDataPart(
            g.Blob.fromBytes(c.mimeType ?? 'image/jpeg', base64Decode(c.data)),
          ),
      ],
      final ChatMessageContentMultiModal c =>
        c.parts
            .map(
              (final p) => switch (p) {
                final ChatMessageContentText c => g.TextPart(c.text),
                final ChatMessageContentImage c =>
                  c.data.startsWith('http')
                      ? g.FileDataPart(g.FileData(fileUri: c.data))
                      : g.InlineDataPart(
                          g.Blob.fromBytes(
                            c.mimeType ?? 'image/jpeg',
                            base64Decode(c.data),
                          ),
                        ),
                ChatMessageContentMultiModal() => throw UnsupportedError(
                  'Cannot have multimodal content in multimodal content',
                ),
              },
            )
            .toList(growable: false),
    };
    return g.Content(role: 'user', parts: contentParts);
  }

  g.Content _mapAIChatMessage(final AIChatMessage msg) {
    final contentParts = [
      if (msg.content.isNotEmpty) g.TextPart(msg.content),
      if (msg.toolCalls.isNotEmpty)
        ...msg.toolCalls.map(
          (final call) => g.FunctionCallPart(
            g.FunctionCall(name: call.name, args: call.arguments),
          ),
        ),
    ];
    return g.Content(role: 'model', parts: contentParts);
  }

  g.FunctionResponsePart _toolMsgToFunctionResponsePart(
    final ToolChatMessage msg,
  ) {
    Map<String, Object?> response;
    try {
      response = jsonDecode(msg.content) as Map<String, Object?>;
    } catch (_) {
      response = {'result': msg.content};
    }
    return g.FunctionResponsePart(
      g.FunctionResponse(name: msg.toolCallId, response: response),
    );
  }

  g.Content _mapCustomChatMessage(final CustomChatMessage msg) {
    return g.Content(role: msg.role, parts: [g.TextPart(msg.content)]);
  }
}

extension GenerateContentResponseMapper on g.GenerateContentResponse {
  ChatResult toChatResult(final String id, final String model) {
    final candidate = candidates?.first;
    if (candidate == null) {
      throw StateError('No candidates in response');
    }

    return ChatResult(
      id: id,
      output: AIChatMessage(
        content:
            candidate.content?.parts
                .map(
                  (p) => switch (p) {
                    final g.TextPart p => p.text,
                    final g.InlineDataPart p => p.inlineData.data,
                    final g.FileDataPart p => p.fileData.fileUri,
                    g.FunctionResponsePart() => '',
                    g.FunctionCallPart() => '',
                    g.ExecutableCodePart() => '',
                    g.CodeExecutionResultPart() => '',
                    g.VideoMetadataPart() => '',
                    g.ThoughtPart() => '',
                    g.ThoughtSignaturePart() => '',
                    g.PartMetadataPart() => '',
                  },
                )
                .nonNulls
                .join('\n') ??
            '',
        toolCalls:
            candidate.content?.parts
                .whereType<g.FunctionCallPart>()
                .map(
                  (final part) => AIChatMessageToolCall(
                    id: part.functionCall.name,
                    name: part.functionCall.name,
                    argumentsRaw: jsonEncode(part.functionCall.args ?? {}),
                    arguments: part.functionCall.args ?? {},
                  ),
                )
                .toList(growable: false) ??
            [],
      ),
      finishReason: _mapFinishReason(candidate.finishReason),
      metadata: {
        'model': model,
        'block_reason': promptFeedback?.blockReason?.name,
        'safety_ratings': candidate.safetyRatings
            ?.map(
              (r) => {
                'category': r.category.name,
                'probability': r.probability.name,
              },
            )
            .toList(growable: false),
        'citation_metadata': candidate.citationMetadata?.citationSources
            ?.map(
              (final g.CitationSource s) => {
                'start_index': s.startIndex,
                'end_index': s.endIndex,
                'uri': s.uri,
                'title': s.title,
                'license': s.license,
                'publication_date': s.publicationDate?.toIso8601String(),
              },
            )
            .toList(growable: false),
        'executable_code': candidate.content?.parts
            .whereType<g.ExecutableCodePart>()
            .map(
              (code) => {
                'language': code.executableCode.language.name,
                'code': code.executableCode.code,
              },
            )
            .toList(growable: false),
        'code_execution_result': candidate.content?.parts
            .whereType<g.CodeExecutionResultPart>()
            .map(
              (result) => {
                'outcome': result.codeExecutionResult.outcome.name,
                'output': result.codeExecutionResult.output,
              },
            )
            .toList(growable: false),
      },
      usage: LanguageModelUsage(
        promptTokens: usageMetadata?.promptTokenCount,
        responseTokens: usageMetadata?.candidatesTokenCount,
        totalTokens: usageMetadata?.totalTokenCount,
      ),
    );
  }

  FinishReason _mapFinishReason(final g.FinishReason? reason) =>
      switch (reason) {
        g.FinishReason.unspecified => FinishReason.unspecified,
        g.FinishReason.stop => FinishReason.stop,
        g.FinishReason.maxTokens => FinishReason.length,
        g.FinishReason.safety => FinishReason.contentFilter,
        g.FinishReason.recitation => FinishReason.recitation,
        g.FinishReason.other => FinishReason.unspecified,
        g.FinishReason.blocklist => FinishReason.contentFilter,
        g.FinishReason.prohibitedContent => FinishReason.contentFilter,
        g.FinishReason.spii => FinishReason.contentFilter,
        g.FinishReason.malformedFunctionCall => FinishReason.unspecified,
        null => FinishReason.unspecified,
      };
}

extension SafetySettingsMapper on List<ChatVertexAISafetySetting> {
  List<g.SafetySetting> toSafetySettings() {
    return map(
      (final setting) => g.SafetySetting(
        category: switch (setting.category) {
          ChatVertexAISafetySettingCategory.unspecified =>
            g.HarmCategory.unspecified,
          ChatVertexAISafetySettingCategory.harassment =>
            g.HarmCategory.harassment,
          ChatVertexAISafetySettingCategory.hateSpeech =>
            g.HarmCategory.hateSpeech,
          ChatVertexAISafetySettingCategory.sexuallyExplicit =>
            g.HarmCategory.sexuallyExplicit,
          ChatVertexAISafetySettingCategory.dangerousContent =>
            g.HarmCategory.dangerousContent,
        },
        threshold: switch (setting.threshold) {
          ChatVertexAISafetySettingThreshold.unspecified =>
            g.HarmBlockThreshold.unspecified,
          ChatVertexAISafetySettingThreshold.blockLowAndAbove =>
            g.HarmBlockThreshold.blockLowAndAbove,
          ChatVertexAISafetySettingThreshold.blockMediumAndAbove =>
            g.HarmBlockThreshold.blockMediumAndAbove,
          ChatVertexAISafetySettingThreshold.blockOnlyHigh =>
            g.HarmBlockThreshold.blockOnlyHigh,
          ChatVertexAISafetySettingThreshold.blockNone =>
            g.HarmBlockThreshold.blockNone,
        },
      ),
    ).toList(growable: false);
  }
}

extension ChatToolListMapper on List<ToolSpec>? {
  List<g.Tool>? toToolList({required final bool enableCodeExecution}) {
    if (this == null && !enableCodeExecution) {
      return null;
    }

    return [
      g.Tool(
        functionDeclarations: this
            ?.map(
              (tool) => g.FunctionDeclaration(
                name: tool.name,
                description: tool.description,
                parameters: tool.inputJsonSchema.toSchema(),
              ),
            )
            .toList(growable: false),
        codeExecution: enableCodeExecution ? <String, dynamic>{} : null,
      ),
    ];
  }
}

extension SchemaMapper on Map<String, dynamic> {
  g.Schema toSchema() {
    final jsonSchema = this;
    final type = jsonSchema['type'] as String;
    final description = jsonSchema['description'] as String?;
    final nullable = jsonSchema['nullable'] as bool?;
    final enumValues = (jsonSchema['enum'] as List?)?.cast<String>();
    final format = jsonSchema['format'] as String?;
    final items = jsonSchema['items'] as Map<String, dynamic>?;
    final properties = jsonSchema['properties'] as Map<String, dynamic>?;
    final requiredProperties = (jsonSchema['required'] as List?)
        ?.cast<String>();

    switch (type) {
      case 'string':
        return g.Schema(
          type: g.SchemaType.string,
          description: description,
          nullable: nullable,
          enumValues: enumValues,
        );
      case 'number':
        return g.Schema(
          type: g.SchemaType.number,
          description: description,
          nullable: nullable,
          format: format,
        );
      case 'integer':
        return g.Schema(
          type: g.SchemaType.integer,
          description: description,
          nullable: nullable,
          format: format,
        );
      case 'boolean':
        return g.Schema(
          type: g.SchemaType.boolean,
          description: description,
          nullable: nullable,
        );
      case 'array':
        if (items != null) {
          final itemsSchema = items.toSchema();
          return g.Schema(
            type: g.SchemaType.array,
            items: itemsSchema,
            description: description,
            nullable: nullable,
          );
        }
        throw ArgumentError('Array schema must have "items" property');
      case 'object':
        if (properties != null) {
          final propertiesSchema = properties.map(
            (key, value) =>
                MapEntry(key, (value as Map<String, dynamic>).toSchema()),
          );
          return g.Schema(
            type: g.SchemaType.object,
            properties: propertiesSchema,
            required: requiredProperties,
            description: description,
            nullable: nullable,
          );
        }
        throw ArgumentError('Object schema must have "properties" property');
      default:
        throw ArgumentError('Invalid schema type: $type');
    }
  }
}

extension ChatToolChoiceMapper on ChatToolChoice {
  Map<String, dynamic> toToolConfig() {
    return switch (this) {
      ChatToolChoiceNone _ => {
        'functionCallingConfig': {'mode': 'NONE'},
      },
      ChatToolChoiceAuto _ => {
        'functionCallingConfig': {'mode': 'AUTO'},
      },
      ChatToolChoiceRequired() => {
        'functionCallingConfig': {'mode': 'ANY'},
      },
      final ChatToolChoiceForced t => {
        'functionCallingConfig': {
          'mode': 'ANY',
          'allowedFunctionNames': [t.name],
        },
      },
    };
  }
}
