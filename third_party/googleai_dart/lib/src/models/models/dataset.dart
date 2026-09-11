import '../copy_with_sentinel.dart';

/// Reference to a training dataset.
class Dataset {
  /// Examples for training.
  final TuningExamples? examples;

  /// Creates a [Dataset].
  const Dataset({this.examples});

  /// Creates a [Dataset] from JSON.
  factory Dataset.fromJson(Map<String, dynamic> json) => Dataset(
    examples: json['examples'] != null
        ? TuningExamples.fromJson(json['examples'] as Map<String, dynamic>)
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (examples != null) 'examples': examples!.toJson(),
  };

  /// Creates a copy with replaced values.
  Dataset copyWith({Object? examples = unsetCopyWithValue}) {
    return Dataset(
      examples: examples == unsetCopyWithValue
          ? this.examples
          : examples as TuningExamples?,
    );
  }
}

/// Training examples for tuning.
class TuningExamples {
  /// List of example pairs.
  final List<TuningExample>? examples;

  /// Creates a [TuningExamples].
  const TuningExamples({this.examples});

  /// Creates a [TuningExamples] from JSON.
  factory TuningExamples.fromJson(Map<String, dynamic> json) => TuningExamples(
    examples: (json['examples'] as List<dynamic>?)
        ?.map((e) => TuningExample.fromJson(e as Map<String, dynamic>))
        .toList(),
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (examples != null) 'examples': examples!.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  TuningExamples copyWith({Object? examples = unsetCopyWithValue}) {
    return TuningExamples(
      examples: examples == unsetCopyWithValue
          ? this.examples
          : examples as List<TuningExample>?,
    );
  }
}

/// A single training example.
class TuningExample {
  /// The input text.
  final String? textInput;

  /// The expected output.
  final String? output;

  /// Creates a [TuningExample].
  const TuningExample({this.textInput, this.output});

  /// Creates a [TuningExample] from JSON.
  factory TuningExample.fromJson(Map<String, dynamic> json) => TuningExample(
    textInput: json['textInput'] as String?,
    output: json['output'] as String?,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (textInput != null) 'textInput': textInput,
    if (output != null) 'output': output,
  };

  /// Creates a copy with replaced values.
  TuningExample copyWith({
    Object? textInput = unsetCopyWithValue,
    Object? output = unsetCopyWithValue,
  }) {
    return TuningExample(
      textInput: textInput == unsetCopyWithValue
          ? this.textInput
          : textInput as String?,
      output: output == unsetCopyWithValue ? this.output : output as String?,
    );
  }
}
