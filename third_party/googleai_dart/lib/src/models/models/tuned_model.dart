import '../copy_with_sentinel.dart';
import 'dataset.dart';
import 'hyperparameters.dart';
import 'tuning_task.dart';

/// A fine-tuned model.
class TunedModel {
  /// The resource name in format `tunedModels/{tunedmodel}`.
  final String? name;

  /// Display name for the model.
  final String? displayName;

  /// Description of the model.
  final String? description;

  /// State of the model.
  final TunedModelState? state;

  /// The timestamp when the model was created.
  final DateTime? createTime;

  /// The timestamp when the model was last updated.
  final DateTime? updateTime;

  /// Tuning task for this model.
  final TuningTask? tuningTask;

  /// The base model being tuned.
  final String? baseModel;

  /// Tuning data for the model.
  final Dataset? tuningData;

  /// Hyperparameters for tuning.
  final Hyperparameters? hyperparameters;

  /// Temperature setting.
  final double? temperature;

  /// Top-p setting.
  final double? topP;

  /// Top-k setting.
  final int? topK;

  /// Creates a [TunedModel].
  const TunedModel({
    this.name,
    this.displayName,
    this.description,
    this.state,
    this.createTime,
    this.updateTime,
    this.tuningTask,
    this.baseModel,
    this.tuningData,
    this.hyperparameters,
    this.temperature,
    this.topP,
    this.topK,
  });

  /// Creates a [TunedModel] from JSON.
  factory TunedModel.fromJson(Map<String, dynamic> json) => TunedModel(
    name: json['name'] as String?,
    displayName: json['displayName'] as String?,
    description: json['description'] as String?,
    state: json['state'] != null
        ? tunedModelStateFromString(json['state'] as String?)
        : null,
    createTime: json['createTime'] != null
        ? DateTime.parse(json['createTime'] as String)
        : null,
    updateTime: json['updateTime'] != null
        ? DateTime.parse(json['updateTime'] as String)
        : null,
    tuningTask: json['tuningTask'] != null
        ? TuningTask.fromJson(json['tuningTask'] as Map<String, dynamic>)
        : null,
    baseModel: json['baseModel'] as String?,
    tuningData: json['tuningData'] != null
        ? Dataset.fromJson(json['tuningData'] as Map<String, dynamic>)
        : null,
    hyperparameters: json['hyperparameters'] != null
        ? Hyperparameters.fromJson(
            json['hyperparameters'] as Map<String, dynamic>,
          )
        : null,
    temperature: (json['temperature'] as num?)?.toDouble(),
    topP: (json['topP'] as num?)?.toDouble(),
    topK: json['topK'] as int?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (name != null) 'name': name,
    if (displayName != null) 'displayName': displayName,
    if (description != null) 'description': description,
    if (state != null) 'state': tunedModelStateToString(state!),
    if (createTime != null) 'createTime': createTime!.toIso8601String(),
    if (updateTime != null) 'updateTime': updateTime!.toIso8601String(),
    if (tuningTask != null) 'tuningTask': tuningTask!.toJson(),
    if (baseModel != null) 'baseModel': baseModel,
    if (tuningData != null) 'tuningData': tuningData!.toJson(),
    if (hyperparameters != null) 'hyperparameters': hyperparameters!.toJson(),
    if (temperature != null) 'temperature': temperature,
    if (topP != null) 'topP': topP,
    if (topK != null) 'topK': topK,
  };

  /// Creates a copy with replaced values.
  TunedModel copyWith({
    Object? name = unsetCopyWithValue,
    Object? displayName = unsetCopyWithValue,
    Object? description = unsetCopyWithValue,
    Object? state = unsetCopyWithValue,
    Object? createTime = unsetCopyWithValue,
    Object? updateTime = unsetCopyWithValue,
    Object? tuningTask = unsetCopyWithValue,
    Object? baseModel = unsetCopyWithValue,
    Object? tuningData = unsetCopyWithValue,
    Object? hyperparameters = unsetCopyWithValue,
    Object? temperature = unsetCopyWithValue,
    Object? topP = unsetCopyWithValue,
    Object? topK = unsetCopyWithValue,
  }) {
    return TunedModel(
      name: name == unsetCopyWithValue ? this.name : name as String?,
      displayName: displayName == unsetCopyWithValue
          ? this.displayName
          : displayName as String?,
      description: description == unsetCopyWithValue
          ? this.description
          : description as String?,
      state: state == unsetCopyWithValue
          ? this.state
          : state as TunedModelState?,
      createTime: createTime == unsetCopyWithValue
          ? this.createTime
          : createTime as DateTime?,
      updateTime: updateTime == unsetCopyWithValue
          ? this.updateTime
          : updateTime as DateTime?,
      tuningTask: tuningTask == unsetCopyWithValue
          ? this.tuningTask
          : tuningTask as TuningTask?,
      baseModel: baseModel == unsetCopyWithValue
          ? this.baseModel
          : baseModel as String?,
      tuningData: tuningData == unsetCopyWithValue
          ? this.tuningData
          : tuningData as Dataset?,
      hyperparameters: hyperparameters == unsetCopyWithValue
          ? this.hyperparameters
          : hyperparameters as Hyperparameters?,
      temperature: temperature == unsetCopyWithValue
          ? this.temperature
          : temperature as double?,
      topP: topP == unsetCopyWithValue ? this.topP : topP as double?,
      topK: topK == unsetCopyWithValue ? this.topK : topK as int?,
    );
  }
}

/// State of a tuned model.
enum TunedModelState {
  /// Unspecified state.
  unspecified,

  /// Model is being created.
  creating,

  /// Model is active and ready.
  active,

  /// Model creation failed.
  failed,
}

/// Converts a string to a [TunedModelState].
TunedModelState tunedModelStateFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'CREATING' => TunedModelState.creating,
    'ACTIVE' => TunedModelState.active,
    'FAILED' => TunedModelState.failed,
    _ => TunedModelState.unspecified,
  };
}

/// Converts a [TunedModelState] to a string.
String tunedModelStateToString(TunedModelState state) {
  return switch (state) {
    TunedModelState.creating => 'CREATING',
    TunedModelState.active => 'ACTIVE',
    TunedModelState.failed => 'FAILED',
    TunedModelState.unspecified => 'STATE_UNSPECIFIED',
  };
}
