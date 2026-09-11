import '../models/interactions/content/content.dart';
import '../models/interactions/interaction.dart';

/// Convenience extensions for [Interaction].
extension InteractionExtensions on Interaction {
  /// Concatenated text from all text outputs.
  ///
  /// Returns null if no text outputs exist.
  ///
  /// Example:
  /// ```dart
  /// final interaction = await client.interactions.create(...);
  /// print(interaction.text); // Prints the generated text
  /// ```
  String? get text {
    final buffer = StringBuffer();
    var hasText = false;
    for (final output in outputs ?? <InteractionContent>[]) {
      if (output is TextContent && output.text != null) {
        buffer.write(output.text);
        hasText = true;
      }
    }
    return hasText ? buffer.toString() : null;
  }

  /// All text content outputs.
  List<TextContent> get textOutputs =>
      outputs?.whereType<TextContent>().toList() ?? [];

  /// All function call outputs.
  List<FunctionCallContent> get functionCallOutputs =>
      outputs?.whereType<FunctionCallContent>().toList() ?? [];

  /// All thought outputs (for reasoning models).
  List<ThoughtContent> get thoughtOutputs =>
      outputs?.whereType<ThoughtContent>().toList() ?? [];

  /// All image outputs.
  List<ImageContent> get imageOutputs =>
      outputs?.whereType<ImageContent>().toList() ?? [];

  /// All audio outputs.
  List<AudioContent> get audioOutputs =>
      outputs?.whereType<AudioContent>().toList() ?? [];

  /// True if the interaction has text output.
  bool get hasTextOutput => textOutputs.isNotEmpty;

  /// True if the interaction has function calls.
  bool get hasFunctionCalls => functionCallOutputs.isNotEmpty;
}
