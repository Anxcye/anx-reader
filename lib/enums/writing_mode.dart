enum WritingModeEnum {
  auto('auto'),
  vertical('vertical-rl'),
  horizontal('horizontal-tb');

  const WritingModeEnum(this.code);

  final String code;

  static WritingModeEnum fromCode(String code) {
    return WritingModeEnum.values.firstWhere((e) => e.code == code);
  }
}
