enum AiExtractionFailurePolicy { confirmCloudFallback }

enum AiExtractionVerificationPolicy { ambiguousOnly }

class AiExtractionConfig {
  const AiExtractionConfig({
    this.enabled = false,
    this.providerId,
    this.failurePolicy = AiExtractionFailurePolicy.confirmCloudFallback,
    this.verificationPolicy = AiExtractionVerificationPolicy.ambiguousOnly,
  });

  final bool enabled;
  final String? providerId;
  final AiExtractionFailurePolicy failurePolicy;
  final AiExtractionVerificationPolicy verificationPolicy;

  bool get isConfigured =>
      enabled && providerId != null && providerId!.trim().isNotEmpty;

  AiExtractionConfig copyWith({bool? enabled, String? providerId}) =>
      AiExtractionConfig(
        enabled: enabled ?? this.enabled,
        providerId: providerId ?? this.providerId,
        failurePolicy: failurePolicy,
        verificationPolicy: verificationPolicy,
      );

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'providerId': providerId,
        'failurePolicy': failurePolicy.name,
        'verificationPolicy': verificationPolicy.name,
      };

  factory AiExtractionConfig.fromJson(Map<String, dynamic> json) =>
      AiExtractionConfig(
        enabled: json['enabled'] == true,
        providerId: json['providerId']?.toString(),
        failurePolicy: AiExtractionFailurePolicy.values.firstWhere(
          (item) => item.name == json['failurePolicy'],
          orElse: () => AiExtractionFailurePolicy.confirmCloudFallback,
        ),
        verificationPolicy: AiExtractionVerificationPolicy.values.firstWhere(
          (item) => item.name == json['verificationPolicy'],
          orElse: () => AiExtractionVerificationPolicy.ambiguousOnly,
        ),
      );
}
