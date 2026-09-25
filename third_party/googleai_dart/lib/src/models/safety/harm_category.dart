/// Harm categories that can be blocked.
enum HarmCategory {
  /// Unspecified harm category.
  unspecified,

  /// Hate speech and content.
  hateSpeech,

  /// Sexually explicit content.
  sexuallyExplicit,

  /// Harassment content.
  harassment,

  /// Dangerous content.
  dangerousContent,

  /// Civic integrity.
  civicIntegrity,
}

/// Converts string to HarmCategory enum.
HarmCategory harmCategoryFromString(String? value) {
  return switch (value?.toUpperCase()) {
    'HARM_CATEGORY_HATE_SPEECH' => HarmCategory.hateSpeech,
    'HARM_CATEGORY_SEXUALLY_EXPLICIT' => HarmCategory.sexuallyExplicit,
    'HARM_CATEGORY_HARASSMENT' => HarmCategory.harassment,
    'HARM_CATEGORY_DANGEROUS_CONTENT' => HarmCategory.dangerousContent,
    'HARM_CATEGORY_CIVIC_INTEGRITY' => HarmCategory.civicIntegrity,
    _ => HarmCategory.unspecified,
  };
}

/// Converts HarmCategory enum to string.
String harmCategoryToString(HarmCategory category) {
  return switch (category) {
    HarmCategory.hateSpeech => 'HARM_CATEGORY_HATE_SPEECH',
    HarmCategory.sexuallyExplicit => 'HARM_CATEGORY_SEXUALLY_EXPLICIT',
    HarmCategory.harassment => 'HARM_CATEGORY_HARASSMENT',
    HarmCategory.dangerousContent => 'HARM_CATEGORY_DANGEROUS_CONTENT',
    HarmCategory.civicIntegrity => 'HARM_CATEGORY_CIVIC_INTEGRITY',
    HarmCategory.unspecified => 'HARM_CATEGORY_UNSPECIFIED',
  };
}
