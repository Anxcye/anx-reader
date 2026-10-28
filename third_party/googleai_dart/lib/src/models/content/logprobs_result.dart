import '../copy_with_sentinel.dart';

/// Token-level log probabilities.
class LogprobsResult {
  /// Top K candidates per token.
  final List<TopCandidates>? topCandidates;

  /// Actually chosen tokens.
  final List<LogprobCandidate>? chosenCandidates;

  /// Creates a [LogprobsResult].
  const LogprobsResult({this.topCandidates, this.chosenCandidates});

  /// Creates a [LogprobsResult] from JSON.
  factory LogprobsResult.fromJson(Map<String, dynamic> json) => LogprobsResult(
    topCandidates: json['topCandidates'] != null
        ? (json['topCandidates'] as List)
              .map((e) => TopCandidates.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
    chosenCandidates: json['chosenCandidates'] != null
        ? (json['chosenCandidates'] as List)
              .map((e) => LogprobCandidate.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (topCandidates != null)
      'topCandidates': topCandidates!.map((e) => e.toJson()).toList(),
    if (chosenCandidates != null)
      'chosenCandidates': chosenCandidates!.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  LogprobsResult copyWith({
    Object? topCandidates = unsetCopyWithValue,
    Object? chosenCandidates = unsetCopyWithValue,
  }) {
    return LogprobsResult(
      topCandidates: topCandidates == unsetCopyWithValue
          ? this.topCandidates
          : topCandidates as List<TopCandidates>?,
      chosenCandidates: chosenCandidates == unsetCopyWithValue
          ? this.chosenCandidates
          : chosenCandidates as List<LogprobCandidate>?,
    );
  }
}

/// Top candidates for a token position.
class TopCandidates {
  /// List of candidate tokens with probabilities.
  final List<LogprobCandidate>? candidates;

  /// Creates a [TopCandidates].
  const TopCandidates({this.candidates});

  /// Creates a [TopCandidates] from JSON.
  factory TopCandidates.fromJson(Map<String, dynamic> json) => TopCandidates(
    candidates: json['candidates'] != null
        ? (json['candidates'] as List)
              .map((e) => LogprobCandidate.fromJson(e as Map<String, dynamic>))
              .toList()
        : null,
  );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (candidates != null)
      'candidates': candidates!.map((e) => e.toJson()).toList(),
  };

  /// Creates a copy with replaced values.
  TopCandidates copyWith({Object? candidates = unsetCopyWithValue}) {
    return TopCandidates(
      candidates: candidates == unsetCopyWithValue
          ? this.candidates
          : candidates as List<LogprobCandidate>?,
    );
  }
}

/// A single candidate token with its log probability.
class LogprobCandidate {
  /// The candidate token string.
  final String? token;

  /// The token's log probability.
  final double? logProbability;

  /// Creates a [LogprobCandidate].
  const LogprobCandidate({this.token, this.logProbability});

  /// Creates a [LogprobCandidate] from JSON.
  factory LogprobCandidate.fromJson(Map<String, dynamic> json) =>
      LogprobCandidate(
        token: json['token'] as String?,
        logProbability: (json['logProbability'] as num?)?.toDouble(),
      );

  /// Converts to JSON.
  Map<String, dynamic> toJson() => {
    if (token != null) 'token': token,
    if (logProbability != null) 'logProbability': logProbability,
  };

  /// Creates a copy with replaced values.
  LogprobCandidate copyWith({
    Object? token = unsetCopyWithValue,
    Object? logProbability = unsetCopyWithValue,
  }) {
    return LogprobCandidate(
      token: token == unsetCopyWithValue ? this.token : token as String?,
      logProbability: logProbability == unsetCopyWithValue
          ? this.logProbability
          : logProbability as double?,
    );
  }
}
