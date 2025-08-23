enum TranslationModeEnum {
  off('off'),
  translationOnly('translation-only'),
  originalOnly('original-only'),
  bilingual('bilingual');

  const TranslationModeEnum(this.code);

  final String code;

  static TranslationModeEnum fromCode(String code) {
    return TranslationModeEnum.values.firstWhere(
      (e) => e.code == code,
      orElse: () => TranslationModeEnum.off,
    );
  }

  String get displayName {
    switch (this) {
      case TranslationModeEnum.off:
        return 'Off';
      case TranslationModeEnum.translationOnly:
        return 'Translation Only';
      case TranslationModeEnum.originalOnly:
        return 'Original Only';
      case TranslationModeEnum.bilingual:
        return 'Bilingual';
    }
  }
}