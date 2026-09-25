import '../copy_with_sentinel.dart';

/// Represents a model available in the GoogleAI API.
class Model {
  /// The resource name in format `models/{model}`.
  final String name;

  /// The name of the base model (e.g., "gemini-3-flash-preview").
  final String? baseModelId;

  /// The human-readable name (e.g., "Gemini 1.5 Pro").
  final String? displayName;

  /// Description of the model.
  final String? description;

  /// Version number of the model.
  final String? version;

  /// Maximum number of input tokens.
  final int? inputTokenLimit;

  /// Maximum number of output tokens.
  final int? outputTokenLimit;

  /// Supported generation methods.
  final List<String>? supportedGenerationMethods;

  /// Temperature range.
  final double? temperature;

  /// The maximum temperature this model can use.
  final double? maxTemperature;

  /// Top-p range.
  final double? topP;

  /// Top-k range.
  final int? topK;

  /// Whether the model supports thinking.
  final bool? thinking;

  /// Creates a [Model].
  const Model({
    required this.name,
    this.baseModelId,
    this.displayName,
    this.description,
    this.version,
    this.inputTokenLimit,
    this.outputTokenLimit,
    this.supportedGenerationMethods,
    this.temperature,
    this.maxTemperature,
    this.topP,
    this.topK,
    this.thinking,
  });

  /// Creates a [Model] from JSON.
  factory Model.fromJson(Map<String, dynamic> json) => Model(
    name: json['name'] as String,
    baseModelId: json['baseModelId'] as String?,
    displayName: json['displayName'] as String?,
    description: json['description'] as String?,
    version: json['version'] as String?,
    inputTokenLimit: json['inputTokenLimit'] as int?,
    outputTokenLimit: json['outputTokenLimit'] as int?,
    supportedGenerationMethods:
        (json['supportedGenerationMethods'] as List<dynamic>?)
            ?.map((e) => e as String)
            .toList(),
    temperature: (json['temperature'] as num?)?.toDouble(),
    maxTemperature: (json['maxTemperature'] as num?)?.toDouble(),
    topP: (json['topP'] as num?)?.toDouble(),
    topK: json['topK'] as int?,
    thinking: json['thinking'] as bool?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    'name': name,
    if (baseModelId != null) 'baseModelId': baseModelId,
    if (displayName != null) 'displayName': displayName,
    if (description != null) 'description': description,
    if (version != null) 'version': version,
    if (inputTokenLimit != null) 'inputTokenLimit': inputTokenLimit,
    if (outputTokenLimit != null) 'outputTokenLimit': outputTokenLimit,
    if (supportedGenerationMethods != null)
      'supportedGenerationMethods': supportedGenerationMethods,
    if (temperature != null) 'temperature': temperature,
    if (maxTemperature != null) 'maxTemperature': maxTemperature,
    if (topP != null) 'topP': topP,
    if (topK != null) 'topK': topK,
    if (thinking != null) 'thinking': thinking,
  };

  /// Creates a copy with replaced values.
  Model copyWith({
    Object? name = unsetCopyWithValue,
    Object? baseModelId = unsetCopyWithValue,
    Object? displayName = unsetCopyWithValue,
    Object? description = unsetCopyWithValue,
    Object? version = unsetCopyWithValue,
    Object? inputTokenLimit = unsetCopyWithValue,
    Object? outputTokenLimit = unsetCopyWithValue,
    Object? supportedGenerationMethods = unsetCopyWithValue,
    Object? temperature = unsetCopyWithValue,
    Object? maxTemperature = unsetCopyWithValue,
    Object? topP = unsetCopyWithValue,
    Object? topK = unsetCopyWithValue,
    Object? thinking = unsetCopyWithValue,
  }) {
    return Model(
      name: name == unsetCopyWithValue ? this.name : name! as String,
      baseModelId: baseModelId == unsetCopyWithValue
          ? this.baseModelId
          : baseModelId as String?,
      displayName: displayName == unsetCopyWithValue
          ? this.displayName
          : displayName as String?,
      description: description == unsetCopyWithValue
          ? this.description
          : description as String?,
      version: version == unsetCopyWithValue
          ? this.version
          : version as String?,
      inputTokenLimit: inputTokenLimit == unsetCopyWithValue
          ? this.inputTokenLimit
          : inputTokenLimit as int?,
      outputTokenLimit: outputTokenLimit == unsetCopyWithValue
          ? this.outputTokenLimit
          : outputTokenLimit as int?,
      supportedGenerationMethods:
          supportedGenerationMethods == unsetCopyWithValue
          ? this.supportedGenerationMethods
          : supportedGenerationMethods as List<String>?,
      temperature: temperature == unsetCopyWithValue
          ? this.temperature
          : temperature as double?,
      maxTemperature: maxTemperature == unsetCopyWithValue
          ? this.maxTemperature
          : maxTemperature as double?,
      topP: topP == unsetCopyWithValue ? this.topP : topP as double?,
      topK: topK == unsetCopyWithValue ? this.topK : topK as int?,
      thinking: thinking == unsetCopyWithValue
          ? this.thinking
          : thinking as bool?,
    );
  }
}
