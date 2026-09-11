import '../copy_with_sentinel.dart';
import 'allowed_tools.dart';
import 'tool_choice_type.dart';

/// Configuration for tool choice.
///
/// Can be either a simple [InteractionToolChoiceType] or a more detailed
/// [AllowedTools] configuration.
class InteractionToolChoice {
  /// Simple tool choice type (auto, any, none, validated).
  final InteractionToolChoiceType? type;

  /// Detailed configuration for allowed tools.
  final AllowedTools? allowedTools;

  /// Creates an [InteractionToolChoice] with a type.
  const InteractionToolChoice.type(this.type) : allowedTools = null;

  /// Creates an [InteractionToolChoice] with allowed tools config.
  const InteractionToolChoice.config(this.allowedTools) : type = null;

  /// Creates an [InteractionToolChoice] from JSON.
  factory InteractionToolChoice.fromJson(dynamic json) {
    if (json is String) {
      return InteractionToolChoice.type(
        interactionToolChoiceTypeFromString(json),
      );
    } else if (json is Map<String, dynamic>) {
      if (json.containsKey('allowed_tools')) {
        return InteractionToolChoice.config(
          AllowedTools.fromJson(json['allowed_tools'] as Map<String, dynamic>),
        );
      }
    }
    return const InteractionToolChoice.type(InteractionToolChoiceType.auto);
  }

  /// Converts to JSON.
  dynamic toJson() {
    if (type != null) {
      return interactionToolChoiceTypeToString(type!);
    } else if (allowedTools != null) {
      return {'allowed_tools': allowedTools!.toJson()};
    }
    return null;
  }

  /// Creates a copy with replaced values.
  InteractionToolChoice copyWith({
    Object? type = unsetCopyWithValue,
    Object? allowedTools = unsetCopyWithValue,
  }) {
    final newType = type == unsetCopyWithValue
        ? this.type
        : type as InteractionToolChoiceType?;
    final newAllowedTools = allowedTools == unsetCopyWithValue
        ? this.allowedTools
        : allowedTools as AllowedTools?;

    if (newType != null) {
      return InteractionToolChoice.type(newType);
    } else if (newAllowedTools != null) {
      return InteractionToolChoice.config(newAllowedTools);
    }
    return const InteractionToolChoice.type(InteractionToolChoiceType.auto);
  }
}
