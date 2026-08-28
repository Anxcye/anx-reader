import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/config/shared_preference_provider.dart';

enum AiTokenUsageRole {
  general,
  localExtraction,
  cloudExtraction,
  cloudVerification,
}

class AiTokenUsageBucket {
  const AiTokenUsageBucket({
    this.inputTokens = 0,
    this.outputTokens = 0,
    this.requests = 0,
    this.estimatedRequests = 0,
  });

  final int inputTokens;
  final int outputTokens;
  final int requests;
  final int estimatedRequests;
  int get totalTokens => inputTokens + outputTokens;

  Map<String, dynamic> toJson() => {
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'requests': requests,
        'estimatedRequests': estimatedRequests,
      };

  factory AiTokenUsageBucket.fromJson(Object? value) {
    final map = value is Map ? Map<String, dynamic>.from(value) : const {};
    int number(String key) =>
        map[key] is num ? (map[key] as num).toInt().clamp(0, 1 << 62) : 0;
    return AiTokenUsageBucket(
      inputTokens: number('inputTokens'),
      outputTokens: number('outputTokens'),
      requests: number('requests'),
      estimatedRequests: number('estimatedRequests'),
    );
  }
}

class AiTokenUsageSnapshot {
  const AiTokenUsageSnapshot({
    required this.month,
    required this.inputTokens,
    required this.outputTokens,
    required this.requests,
    required this.estimatedRequests,
    required this.startedAt,
    this.byRole = const {},
    this.storyBaselineInputTokens = 0,
    this.storyCloudInputTokens = 0,
  });

  factory AiTokenUsageSnapshot.empty(DateTime now) => AiTokenUsageSnapshot(
        month: _monthKey(now),
        inputTokens: 0,
        outputTokens: 0,
        requests: 0,
        estimatedRequests: 0,
        startedAt: now.millisecondsSinceEpoch,
      );

  factory AiTokenUsageSnapshot.fromJson(
    Map<String, dynamic> json,
    DateTime now,
  ) {
    if (json['month'] != _monthKey(now)) {
      return AiTokenUsageSnapshot.empty(now);
    }
    return AiTokenUsageSnapshot(
      month: json['month']?.toString() ?? _monthKey(now),
      inputTokens: _nonNegativeInt(json['inputTokens']),
      outputTokens: _nonNegativeInt(json['outputTokens']),
      requests: _nonNegativeInt(json['requests']),
      estimatedRequests: _nonNegativeInt(json['estimatedRequests']),
      startedAt: _nonNegativeInt(json['startedAt']) == 0
          ? now.millisecondsSinceEpoch
          : _nonNegativeInt(json['startedAt']),
      byRole: {
        for (final role in AiTokenUsageRole.values)
          if ((json['byRole'] as Map?)?[role.name] != null)
            role: AiTokenUsageBucket.fromJson(
              (json['byRole'] as Map?)?[role.name],
            ),
      },
      storyBaselineInputTokens:
          _nonNegativeInt(json['storyBaselineInputTokens']),
      storyCloudInputTokens: _nonNegativeInt(json['storyCloudInputTokens']),
    );
  }

  final String month;
  final int inputTokens;
  final int outputTokens;
  final int requests;
  final int estimatedRequests;
  final int startedAt;
  final Map<AiTokenUsageRole, AiTokenUsageBucket> byRole;
  final int storyBaselineInputTokens;
  final int storyCloudInputTokens;

  double? get storyCloudSavingRate => storyBaselineInputTokens <= 0
      ? null
      : (1 - storyCloudInputTokens / storyBaselineInputTokens).clamp(0, 1);

  int get totalTokens => inputTokens + outputTokens;
  bool get containsEstimates => estimatedRequests > 0;

  AiTokenUsageSnapshot add({
    required int inputTokens,
    required int outputTokens,
    required bool estimated,
  }) =>
      AiTokenUsageSnapshot(
        month: month,
        inputTokens: this.inputTokens + inputTokens.clamp(0, 1 << 62),
        outputTokens: this.outputTokens + outputTokens.clamp(0, 1 << 62),
        requests: requests + 1,
        estimatedRequests: estimatedRequests + (estimated ? 1 : 0),
        startedAt: startedAt,
        byRole: byRole,
        storyBaselineInputTokens: storyBaselineInputTokens,
        storyCloudInputTokens: storyCloudInputTokens,
      );

  AiTokenUsageSnapshot addRole({
    required AiTokenUsageRole role,
    required int inputTokens,
    required int outputTokens,
    required bool estimated,
  }) {
    final previous = byRole[role] ?? const AiTokenUsageBucket();
    return AiTokenUsageSnapshot(
      month: month,
      inputTokens: this.inputTokens + inputTokens,
      outputTokens: this.outputTokens + outputTokens,
      requests: requests + 1,
      estimatedRequests: estimatedRequests + (estimated ? 1 : 0),
      startedAt: startedAt,
      byRole: {
        ...byRole,
        role: AiTokenUsageBucket(
          inputTokens: previous.inputTokens + inputTokens,
          outputTokens: previous.outputTokens + outputTokens,
          requests: previous.requests + 1,
          estimatedRequests: previous.estimatedRequests + (estimated ? 1 : 0),
        ),
      },
      storyBaselineInputTokens: storyBaselineInputTokens,
      storyCloudInputTokens: storyCloudInputTokens,
    );
  }

  AiTokenUsageSnapshot addStorySavings({
    required int baselineInputTokens,
    required int cloudInputTokens,
  }) =>
      AiTokenUsageSnapshot(
        month: month,
        inputTokens: inputTokens,
        outputTokens: outputTokens,
        requests: requests,
        estimatedRequests: estimatedRequests,
        startedAt: startedAt,
        byRole: byRole,
        storyBaselineInputTokens:
            storyBaselineInputTokens + baselineInputTokens,
        storyCloudInputTokens: storyCloudInputTokens + cloudInputTokens,
      );

  Map<String, dynamic> toJson() => {
        'month': month,
        'inputTokens': inputTokens,
        'outputTokens': outputTokens,
        'requests': requests,
        'estimatedRequests': estimatedRequests,
        'startedAt': startedAt,
        'byRole': {
          for (final entry in byRole.entries)
            entry.key.name: entry.value.toJson(),
        },
        'storyBaselineInputTokens': storyBaselineInputTokens,
        'storyCloudInputTokens': storyCloudInputTokens,
      };

  static int _nonNegativeInt(Object? value) =>
      value is num ? value.toInt().clamp(0, 1 << 62) : 0;
}

class AiTokenUsageService {
  AiTokenUsageService({DateTime Function()? clock})
      : _clock = clock ?? DateTime.now;

  static const storageKey = 'aiTokenUsageMonthly';
  final DateTime Function() _clock;
  static final Object _roleZoneKey = Object();

  Future<T> runWithRole<T>(
    AiTokenUsageRole role,
    Future<T> Function() operation,
  ) =>
      runZoned(operation, zoneValues: {_roleZoneKey: role});

  AiTokenUsageSnapshot snapshot() {
    final now = _clock();
    final raw = Prefs().prefs.getString(storageKey);
    if (raw == null || raw.isEmpty) return AiTokenUsageSnapshot.empty(now);
    try {
      return AiTokenUsageSnapshot.fromJson(
        Map<String, dynamic>.from(jsonDecode(raw) as Map),
        now,
      );
    } catch (_) {
      return AiTokenUsageSnapshot.empty(now);
    }
  }

  void record({
    required int inputTokens,
    required int outputTokens,
    required bool estimated,
  }) {
    if (inputTokens <= 0 && outputTokens <= 0) return;
    final role = Zone.current[_roleZoneKey] as AiTokenUsageRole? ??
        AiTokenUsageRole.general;
    final updated = snapshot().addRole(
      role: role,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      estimated: estimated,
    );
    Prefs().prefs.setString(storageKey, jsonEncode(updated.toJson()));
  }

  void recordStorySavings({
    required int baselineInputTokens,
    required int cloudInputTokens,
  }) {
    if (baselineInputTokens <= 0 && cloudInputTokens <= 0) return;
    final updated = snapshot().addStorySavings(
      baselineInputTokens: baselineInputTokens,
      cloudInputTokens: cloudInputTokens.clamp(0, 1 << 62),
    );
    Prefs().prefs.setString(storageKey, jsonEncode(updated.toJson()));
  }

  void reset() {
    final empty = AiTokenUsageSnapshot.empty(_clock());
    Prefs().prefs.setString(storageKey, jsonEncode(empty.toJson()));
  }
}

String _monthKey(DateTime value) =>
    '${value.year}-${value.month.toString().padLeft(2, '0')}';

final aiTokenUsageService = AiTokenUsageService();
