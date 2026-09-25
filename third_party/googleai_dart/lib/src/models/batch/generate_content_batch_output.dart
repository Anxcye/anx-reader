import '../copy_with_sentinel.dart';
import 'inlined_responses.dart';

/// The output of a GenerateContent batch request.
class GenerateContentBatchOutput {
  /// The file ID of the file containing the responses.
  ///
  /// The file will be a JSONL file with a single response per line.
  /// The responses will be `GenerateContentResponse` messages formatted as JSON.
  /// The responses will be written in the same order as the input requests.
  final String? responsesFile;

  /// The responses to the requests in the batch (inline).
  ///
  /// Returned when the batch was built using inlined requests.
  /// The responses will be in the same order as the input requests.
  final InlinedResponses? inlinedResponses;

  /// Creates a [GenerateContentBatchOutput].
  const GenerateContentBatchOutput({this.responsesFile, this.inlinedResponses});

  /// Creates a [GenerateContentBatchOutput] from JSON.
  factory GenerateContentBatchOutput.fromJson(Map<String, dynamic> json) =>
      GenerateContentBatchOutput(
        responsesFile: json['responsesFile'] as String?,
        inlinedResponses: json['inlinedResponses'] != null
            ? InlinedResponses.fromJson(
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
  GenerateContentBatchOutput copyWith({
    Object? responsesFile = unsetCopyWithValue,
    Object? inlinedResponses = unsetCopyWithValue,
  }) {
    return GenerateContentBatchOutput(
      responsesFile: responsesFile == unsetCopyWithValue
          ? this.responsesFile
          : responsesFile as String?,
      inlinedResponses: inlinedResponses == unsetCopyWithValue
          ? this.inlinedResponses
          : inlinedResponses as InlinedResponses?,
    );
  }
}
