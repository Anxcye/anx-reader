import '../copy_with_sentinel.dart';
import 'batch_state.dart';
import 'embed_content_batch_output.dart';
import 'embed_content_batch_stats.dart';
import 'input_embed_content_config.dart';

/// A resource representing a batch of `EmbedContent` requests.
class EmbedContentBatch {
  /// The user-defined name of this batch.
  final String? displayName;

  /// The name of the `Model` to use for generating the embeddings.
  ///
  /// Format: `models/{model}`.
  final String? model;

  /// Input configuration of the instances on which batch processing is performed.
  final InputEmbedContentConfig? inputConfig;

  /// The resource name of the batch.
  ///
  /// Format: `batches/{batch_id}`.
  final String? name;

  /// The output of the batch request.
  final EmbedContentBatchOutput? output;

  /// The time at which the batch was created.
  final DateTime? createTime;

  /// The time at which the batch processing completed.
  final DateTime? endTime;

  /// The time at which the batch was last updated.
  final DateTime? updateTime;

  /// Stats about the batch.
  final EmbedContentBatchStats? batchStats;

  /// The state of the batch.
  final BatchState? state;

  /// The priority of the batch.
  ///
  /// Batches with a higher priority value will be processed before batches
  /// with a lower priority value. Negative values are allowed. Default is 0.
  final int? priority;

  /// Creates an [EmbedContentBatch].
  const EmbedContentBatch({
    this.displayName,
    this.model,
    this.inputConfig,
    this.name,
    this.output,
    this.createTime,
    this.endTime,
    this.updateTime,
    this.batchStats,
    this.state,
    this.priority,
  });

  /// Creates an [EmbedContentBatch] from JSON.
  factory EmbedContentBatch.fromJson(Map<String, dynamic> json) =>
      EmbedContentBatch(
        name: json['name'] as String?,
        displayName: json['displayName'] as String?,
        model: json['model'] as String?,
        inputConfig: json['inputConfig'] != null
            ? InputEmbedContentConfig.fromJson(
                json['inputConfig'] as Map<String, dynamic>,
              )
            : null,
        output: json['output'] != null
            ? EmbedContentBatchOutput.fromJson(
                json['output'] as Map<String, dynamic>,
              )
            : null,
        createTime: json['createTime'] != null
            ? DateTime.parse(json['createTime'] as String)
            : null,
        endTime: json['endTime'] != null
            ? DateTime.parse(json['endTime'] as String)
            : null,
        updateTime: json['updateTime'] != null
            ? DateTime.parse(json['updateTime'] as String)
            : null,
        batchStats: json['batchStats'] != null
            ? EmbedContentBatchStats.fromJson(
                json['batchStats'] as Map<String, dynamic>,
              )
            : null,
        state: json['state'] != null
            ? batchStateFromString(json['state'] as String)
            : null,
        priority: json['priority'] != null
            ? int.parse(json['priority'] as String)
            : null,
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (displayName != null) 'displayName': displayName,
    if (model != null) 'model': model,
    if (inputConfig != null) 'inputConfig': inputConfig!.toJson(),
    if (output != null) 'output': output!.toJson(),
    if (createTime != null) 'createTime': createTime!.toIso8601String(),
    if (endTime != null) 'endTime': endTime!.toIso8601String(),
    if (updateTime != null) 'updateTime': updateTime!.toIso8601String(),
    if (batchStats != null) 'batchStats': batchStats!.toJson(),
    if (state != null) 'state': batchStateToString(state!),
    if (priority != null) 'priority': priority.toString(),
  };

  /// Creates a copy with replaced values.
  EmbedContentBatch copyWith({
    Object? name = unsetCopyWithValue,
    Object? displayName = unsetCopyWithValue,
    Object? model = unsetCopyWithValue,
    Object? inputConfig = unsetCopyWithValue,
    Object? output = unsetCopyWithValue,
    Object? createTime = unsetCopyWithValue,
    Object? endTime = unsetCopyWithValue,
    Object? updateTime = unsetCopyWithValue,
    Object? batchStats = unsetCopyWithValue,
    Object? state = unsetCopyWithValue,
    Object? priority = unsetCopyWithValue,
  }) {
    return EmbedContentBatch(
      name: name == unsetCopyWithValue ? this.name : name as String?,
      displayName: displayName == unsetCopyWithValue
          ? this.displayName
          : displayName as String?,
      model: model == unsetCopyWithValue ? this.model : model as String?,
      inputConfig: inputConfig == unsetCopyWithValue
          ? this.inputConfig
          : inputConfig as InputEmbedContentConfig?,
      output: output == unsetCopyWithValue
          ? this.output
          : output as EmbedContentBatchOutput?,
      createTime: createTime == unsetCopyWithValue
          ? this.createTime
          : createTime as DateTime?,
      endTime: endTime == unsetCopyWithValue
          ? this.endTime
          : endTime as DateTime?,
      updateTime: updateTime == unsetCopyWithValue
          ? this.updateTime
          : updateTime as DateTime?,
      batchStats: batchStats == unsetCopyWithValue
          ? this.batchStats
          : batchStats as EmbedContentBatchStats?,
      state: state == unsetCopyWithValue ? this.state : state as BatchState?,
      priority: priority == unsetCopyWithValue
          ? this.priority
          : priority as int?,
    );
  }
}
