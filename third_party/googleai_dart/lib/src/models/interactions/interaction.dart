import '../copy_with_sentinel.dart';
import 'agent_config.dart';
import 'content/content.dart';
import 'generation_config.dart';
import 'interaction_status.dart';
import 'response_modality.dart';
import 'tools/tools.dart';
import 'usage.dart';

/// The Interaction resource.
///
/// Represents a single interaction with the Gemini API using server-side
/// state management.
class Interaction {
  /// A unique identifier for the interaction.
  final String id;

  /// The status of the interaction.
  final InteractionStatus status;

  /// The name of the model used for generating the interaction.
  final String? model;

  /// The name of the agent used for generating the interaction.
  final String? agent;

  /// The time at which the interaction was created (ISO 8601 format).
  final DateTime? created;

  /// The time at which the interaction was last updated (ISO 8601 format).
  final DateTime? updated;

  /// The role of the interaction response.
  final String? role;

  /// Output only. Responses from the model.
  final List<InteractionContent>? outputs;

  /// Statistics on the interaction request's token usage.
  final InteractionUsage? usage;

  /// The object type of the interaction. Always 'interaction'.
  final String object;

  /// The ID of the previous interaction, if any.
  final String? previousInteractionId;

  /// Creates an [Interaction] instance.
  const Interaction({
    required this.id,
    required this.status,
    this.model,
    this.agent,
    this.created,
    this.updated,
    this.role,
    this.outputs,
    this.usage,
    this.object = 'interaction',
    this.previousInteractionId,
  });

  /// Creates an [Interaction] from JSON.
  factory Interaction.fromJson(Map<String, dynamic> json) => Interaction(
    id: json['id'] as String,
    status: InteractionStatus.fromString(json['status'] as String?),
    model: json['model'] as String?,
    agent: json['agent'] as String?,
    created: json['created'] != null
        ? DateTime.parse(json['created'] as String)
        : null,
    updated: json['updated'] != null
        ? DateTime.parse(json['updated'] as String)
        : null,
    role: json['role'] as String?,
    outputs: (json['outputs'] as List<dynamic>?)
        ?.map((e) => InteractionContent.fromJson(e as Map<String, dynamic>))
        .toList(),
    usage: json['usage'] != null
        ? InteractionUsage.fromJson(json['usage'] as Map<String, dynamic>)
        : null,
    object: json['object'] as String? ?? 'interaction',
    previousInteractionId: json['previous_interaction_id'] as String?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'id': id,
    'status': status.toJson(),
    if (model != null) 'model': model,
    if (agent != null) 'agent': agent,
    if (created != null) 'created': created!.toIso8601String(),
    if (updated != null) 'updated': updated!.toIso8601String(),
    if (role != null) 'role': role,
    if (outputs != null) 'outputs': outputs!.map((e) => e.toJson()).toList(),
    if (usage != null) 'usage': usage!.toJson(),
    'object': object,
    if (previousInteractionId != null)
      'previous_interaction_id': previousInteractionId,
  };

  /// Creates a copy with replaced values.
  Interaction copyWith({
    Object? id = unsetCopyWithValue,
    Object? status = unsetCopyWithValue,
    Object? model = unsetCopyWithValue,
    Object? agent = unsetCopyWithValue,
    Object? created = unsetCopyWithValue,
    Object? updated = unsetCopyWithValue,
    Object? role = unsetCopyWithValue,
    Object? outputs = unsetCopyWithValue,
    Object? usage = unsetCopyWithValue,
    Object? object = unsetCopyWithValue,
    Object? previousInteractionId = unsetCopyWithValue,
  }) {
    return Interaction(
      id: id == unsetCopyWithValue ? this.id : id! as String,
      status: status == unsetCopyWithValue
          ? this.status
          : status! as InteractionStatus,
      model: model == unsetCopyWithValue ? this.model : model as String?,
      agent: agent == unsetCopyWithValue ? this.agent : agent as String?,
      created: created == unsetCopyWithValue
          ? this.created
          : created as DateTime?,
      updated: updated == unsetCopyWithValue
          ? this.updated
          : updated as DateTime?,
      role: role == unsetCopyWithValue ? this.role : role as String?,
      outputs: outputs == unsetCopyWithValue
          ? this.outputs
          : outputs as List<InteractionContent>?,
      usage: usage == unsetCopyWithValue
          ? this.usage
          : usage as InteractionUsage?,
      object: object == unsetCopyWithValue ? this.object : object! as String,
      previousInteractionId: previousInteractionId == unsetCopyWithValue
          ? this.previousInteractionId
          : previousInteractionId as String?,
    );
  }
}

/// Parameters for creating an interaction with a model.
class CreateModelInteractionParams {
  /// The name of the model to use.
  final String model;

  /// The input for the interaction.
  ///
  /// Can be a [String] for simple text, a [List<dynamic>] for multimodal
  /// content, or a [List<Turn>] for multi-turn conversations.
  final Object? input;

  /// System instruction for the interaction.
  final String? systemInstruction;

  /// A list of tool declarations the model may call during interaction.
  final List<InteractionTool>? tools;

  /// Configuration parameters for the model interaction.
  final InteractionGenerationConfig? generationConfig;

  /// The requested modalities of the response.
  final List<InteractionResponseModality>? responseModalities;

  /// The mime type of the response.
  final String? responseMimeType;

  /// The ID of a previous interaction to continue from.
  final String? previousInteractionId;

  /// Whether to run the model interaction in the background.
  final bool? background;

  /// Creates a [CreateModelInteractionParams] instance.
  const CreateModelInteractionParams({
    required this.model,
    this.input,
    this.systemInstruction,
    this.tools,
    this.generationConfig,
    this.responseModalities,
    this.responseMimeType,
    this.previousInteractionId,
    this.background,
  });

  /// Creates from JSON.
  factory CreateModelInteractionParams.fromJson(Map<String, dynamic> json) =>
      CreateModelInteractionParams(
        model: json['model'] as String,
        input: json['input'],
        systemInstruction: json['system_instruction'] as String?,
        tools: (json['tools'] as List<dynamic>?)
            ?.map((e) => InteractionTool.fromJson(e as Map<String, dynamic>))
            .toList(),
        generationConfig: json['generation_config'] != null
            ? InteractionGenerationConfig.fromJson(
                json['generation_config'] as Map<String, dynamic>,
              )
            : null,
        responseModalities: (json['response_modalities'] as List<dynamic>?)
            ?.map((e) => interactionResponseModalityFromString(e as String))
            .toList(),
        responseMimeType: json['response_mime_type'] as String?,
        previousInteractionId: json['previous_interaction_id'] as String?,
        background: json['background'] as bool?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'model': model,
    if (input != null) 'input': input,
    if (systemInstruction != null) 'system_instruction': systemInstruction,
    if (tools != null) 'tools': tools!.map((e) => e.toJson()).toList(),
    if (generationConfig != null)
      'generation_config': generationConfig!.toJson(),
    if (responseModalities != null)
      'response_modalities': responseModalities!
          .map(interactionResponseModalityToString)
          .toList(),
    if (responseMimeType != null) 'response_mime_type': responseMimeType,
    if (previousInteractionId != null)
      'previous_interaction_id': previousInteractionId,
    if (background != null) 'background': background,
  };
}

/// Parameters for creating an interaction with an agent.
class CreateAgentInteractionParams {
  /// The name of the agent to use.
  final String agent;

  /// The input for the interaction.
  final Object? input;

  /// Configuration for the agent.
  final AgentConfig? agentConfig;

  /// The ID of a previous interaction to continue from.
  final String? previousInteractionId;

  /// Whether to run the agent interaction in the background.
  final bool? background;

  /// Creates a [CreateAgentInteractionParams] instance.
  const CreateAgentInteractionParams({
    required this.agent,
    this.input,
    this.agentConfig,
    this.previousInteractionId,
    this.background,
  });

  /// Creates from JSON.
  factory CreateAgentInteractionParams.fromJson(Map<String, dynamic> json) =>
      CreateAgentInteractionParams(
        agent: json['agent'] as String,
        input: json['input'],
        agentConfig: json['agent_config'] != null
            ? AgentConfig.fromJson(json['agent_config'] as Map<String, dynamic>)
            : null,
        previousInteractionId: json['previous_interaction_id'] as String?,
        background: json['background'] as bool?,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'agent': agent,
    if (input != null) 'input': input,
    if (agentConfig != null) 'agent_config': agentConfig!.toJson(),
    if (previousInteractionId != null)
      'previous_interaction_id': previousInteractionId,
    if (background != null) 'background': background,
  };
}
