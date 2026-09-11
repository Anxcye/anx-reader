import '../copy_with_sentinel.dart';
import 'response_modality.dart';

/// Token count for a single response modality.
class ModalityTokens {
  /// The modality associated with the token count.
  final InteractionResponseModality? modality;

  /// Number of tokens for the modality.
  final int? tokens;

  /// Creates a [ModalityTokens] instance.
  const ModalityTokens({this.modality, this.tokens});

  /// Creates a [ModalityTokens] from JSON.
  factory ModalityTokens.fromJson(Map<String, dynamic> json) => ModalityTokens(
    modality: json['modality'] != null
        ? interactionResponseModalityFromString(json['modality'] as String?)
        : null,
    tokens: json['tokens'] as int?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (modality != null)
      'modality': interactionResponseModalityToString(modality!),
    if (tokens != null) 'tokens': tokens,
  };

  /// Creates a copy with replaced values.
  ModalityTokens copyWith({
    Object? modality = unsetCopyWithValue,
    Object? tokens = unsetCopyWithValue,
  }) {
    return ModalityTokens(
      modality: modality == unsetCopyWithValue
          ? this.modality
          : modality as InteractionResponseModality?,
      tokens: tokens == unsetCopyWithValue ? this.tokens : tokens as int?,
    );
  }
}
