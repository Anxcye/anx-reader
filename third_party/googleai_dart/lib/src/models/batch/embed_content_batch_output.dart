import '../copy_with_sentinel.dart';
import 'inlined_embed_content_responses.dart';

/// The output of an EmbedContent batch request.
class EmbedContentBatchOutput {
  /// The file ID of the file containing the responses.
  ///
  /// The file will be a JSONL file with a single response per line.
  /// The responses will be `EmbedContentResponse` messages formatted as JSON.
  /// The responses will be written in the same order as the input requests.
  final String? responsesFile;

  /// The responses to the requests in the batch (inline).
  ///
  /// Returned when the batch was built using inlined requests.
  /// The responses will be in the same order as the input requests.
  final InlinedEmbedContentResponses? inlinedResponses;

  /// Creates an [EmbedContentBatchOutput].
  const EmbedContentBatchOutput({this.responsesFile, this.inlinedResponses});

  /// Creates an [EmbedContentBatchOutput] from JSON.
  factory EmbedContentBatchOutput.fromJson(Map<String, dynamic> json) =>
      EmbedContentBatchOutput(
        responsesFile: json['responsesFile'] as String?,
        inlinedResponses: json['inlinedResponses'] != null
            ? InlinedEmbedContentResponses.fromJson(
                json['inlinedResponses'] as Map<String, dynamic>,
              )
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (responsesFile != null) 'responsesFile': responsesFile,
    if (inlinedResponses != null)
      'inlinedResponses': inlinedResponses!.toJson(),
  };

  /// Creates a copy with replaced values.
  EmbedContentBatchOutput copyWith({
    Object? responsesFile = unsetCopyWithValue,
    Object? inlinedResponses = unsetCopyWithValue,
  }) {
    return EmbedContentBatchOutput(
      responsesFile: responsesFile == unsetCopyWithValue
          ? this.responsesFile
          : responsesFile as String?,
      inlinedResponses: inlinedResponses == unsetCopyWithValue
          ? this.inlinedResponses
          : inlinedResponses as InlinedEmbedContentResponses?,
    );
  }
}
