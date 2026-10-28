import '../copy_with_sentinel.dart';
import 'tool_choice_type.dart';

/// Configuration for allowed tools.
class AllowedTools {
  /// The mode of the tool choice.
  final InteractionToolChoiceType? mode;

  /// The names of the allowed tools.
  final List<String>? tools;

  /// Creates an [AllowedTools] instance.
  const AllowedTools({this.mode, this.tools});

  /// Creates an [AllowedTools] from JSON.
  factory AllowedTools.fromJson(Map<String, dynamic> json) => AllowedTools(
    mode: json['mode'] != null
        ? interactionToolChoiceTypeFromString(json['mode'] as String?)
        : null,
    tools: (json['tools'] as List<dynamic>?)?.cast<String>(),
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (mode != null) 'mode': interactionToolChoiceTypeToString(mode!),
    if (tools != null) 'tools': tools,
  };

  /// Creates a copy with replaced values.
  AllowedTools copyWith({
    Object? mode = unsetCopyWithValue,
    Object? tools = unsetCopyWithValue,
  }) {
    return AllowedTools(
      mode: mode == unsetCopyWithValue
          ? this.mode
          : mode as InteractionToolChoiceType?,
      tools: tools == unsetCopyWithValue ? this.tools : tools as List<String>?,
    );
  }
}
