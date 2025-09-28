import 'dart:convert';

class ChapterSplitSampleMatch {
  const ChapterSplitSampleMatch({
    required this.sample,
    required this.isMatch,
  });

  final String sample;
  final bool isMatch;
}

class ChapterSplitRuleEvaluation {
  const ChapterSplitRuleEvaluation({
    required this.isValid,
    this.errorMessage,
    required this.sampleMatches,
  });

  final bool isValid;
  final String? errorMessage;
  final List<ChapterSplitSampleMatch> sampleMatches;
}

class ChapterSplitRule {
  const ChapterSplitRule({
    required this.id,
    required this.name,
    required this.pattern,
    required this.samples,
    this.caseSensitive = false,
    this.multiLine = true,
    this.isBuiltin = false,
  });

  final String id;
  final String name;
  final String pattern;
  final List<String> samples;
  final bool caseSensitive;
  final bool multiLine;
  final bool isBuiltin;

  factory ChapterSplitRule.fromJson(String json) {
    final Map<String, dynamic> data = jsonDecode(json) as Map<String, dynamic>;
    return ChapterSplitRule.fromMap(data);
  }

  factory ChapterSplitRule.fromMap(Map<String, dynamic> map) {
    return ChapterSplitRule(
      id: map['id'] as String,
      name: map['name'] as String,
      pattern: map['pattern'] as String,
      samples: (map['samples'] as List<dynamic>).cast<String>(),
      caseSensitive: map['caseSensitive'] as bool? ?? false,
      multiLine: map['multiLine'] as bool? ?? true,
      isBuiltin: map['isBuiltin'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'pattern': pattern,
      'samples': samples,
      'caseSensitive': caseSensitive,
      'multiLine': multiLine,
      'isBuiltin': isBuiltin,
    };
  }

  String toJson() => jsonEncode(toMap());

  ChapterSplitRule copyWith({
    String? id,
    String? name,
    String? pattern,
    List<String>? samples,
    bool? caseSensitive,
    bool? multiLine,
    bool? isBuiltin,
  }) {
    return ChapterSplitRule(
      id: id ?? this.id,
      name: name ?? this.name,
      pattern: pattern ?? this.pattern,
      samples: samples ?? List<String>.from(this.samples),
      caseSensitive: caseSensitive ?? this.caseSensitive,
      multiLine: multiLine ?? this.multiLine,
      isBuiltin: isBuiltin ?? this.isBuiltin,
    );
  }

  RegExp buildRegExp() {
    return RegExp(
      pattern,
      caseSensitive: caseSensitive,
      multiLine: multiLine,
    );
  }

  ChapterSplitRuleEvaluation evaluateSamples({List<String>? overrideSamples}) {
    final List<String> targetSamples = overrideSamples ?? samples;
    try {
      final regExp = buildRegExp();
      final matches = targetSamples
          .map((sample) => ChapterSplitSampleMatch(
                sample: sample,
                isMatch: regExp.hasMatch(sample),
              ))
          .toList();

      return ChapterSplitRuleEvaluation(
        isValid: true,
        errorMessage: null,
        sampleMatches: matches,
      );
    } on FormatException catch (error) {
      return ChapterSplitRuleEvaluation(
        isValid: false,
        errorMessage: error.message,
        sampleMatches: targetSamples
            .map((sample) =>
                ChapterSplitSampleMatch(sample: sample, isMatch: false))
            .toList(),
      );
    }
  }
}
