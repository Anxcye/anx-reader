import '../copy_with_sentinel.dart';
import 'thinking_summaries.dart';

/// Base class for agent configurations.
sealed class AgentConfig {
  /// The type of agent configuration.
  String get type;

  const AgentConfig();

  /// Creates an [AgentConfig] from JSON.
  factory AgentConfig.fromJson(Map<String, dynamic> json) {
    final type = json['type'] as String?;
    return switch (type) {
      'dynamic' => DynamicAgentConfig.fromJson(json),
      'deep-research' => DeepResearchAgentConfig.fromJson(json),
      _ => DynamicAgentConfig.fromJson(json),
    };
  }

  /// Converts to JSON.
  Map<String, dynamic> toJson();
}

/// Configuration for dynamic agents.
class DynamicAgentConfig extends AgentConfig {
  @override
  String get type => 'dynamic';

  /// Additional properties for the dynamic agent.
  final Map<String, dynamic>? additionalProperties;

  /// Creates a [DynamicAgentConfig] instance.
  const DynamicAgentConfig({this.additionalProperties});

  /// Creates a [DynamicAgentConfig] from JSON.
  factory DynamicAgentConfig.fromJson(Map<String, dynamic> json) {
    final props = Map<String, dynamic>.from(json)..remove('type');
    return DynamicAgentConfig(
      additionalProperties: props.isNotEmpty ? props : null,
    );
  }

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (additionalProperties != null) ...additionalProperties!,
  };

  /// Creates a copy with replaced values.
  DynamicAgentConfig copyWith({
    Object? additionalProperties = unsetCopyWithValue,
  }) {
    return DynamicAgentConfig(
      additionalProperties: additionalProperties == unsetCopyWithValue
          ? this.additionalProperties
          : additionalProperties as Map<String, dynamic>?,
    );
  }
}

/// Configuration for the Deep Research agent.
class DeepResearchAgentConfig extends AgentConfig {
  @override
  String get type => 'deep-research';

  /// Whether to include thought summaries in the response.
  final InteractionThinkingSummaries? thinkingSummaries;

  /// Creates a [DeepResearchAgentConfig] instance.
  const DeepResearchAgentConfig({this.thinkingSummaries});

  /// Creates a [DeepResearchAgentConfig] from JSON.
  factory DeepResearchAgentConfig.fromJson(Map<String, dynamic> json) =>
      DeepResearchAgentConfig(
        thinkingSummaries: json['thinking_summaries'] != null
            ? interactionThinkingSummariesFromString(
                json['thinking_summaries'] as String?,
              )
            : null,
      );

  @override
  Map<String, dynamic> toJson() => {
    'type': type,
    if (thinkingSummaries != null)
      'thinking_summaries': interactionThinkingSummariesToString(
        thinkingSummaries!,
      ),
  };

  /// Creates a copy with replaced values.
  DeepResearchAgentConfig copyWith({
    Object? thinkingSummaries = unsetCopyWithValue,
  }) {
    return DeepResearchAgentConfig(
      thinkingSummaries: thinkingSummaries == unsetCopyWithValue
          ? this.thinkingSummaries
          : thinkingSummaries as InteractionThinkingSummaries?,
    );
  }
}
