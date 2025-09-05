enum TextAlignmentEnum {
  auto('auto'),
  left('left'),
  center('center'),
  right('right'),
  justify('justify');

  const TextAlignmentEnum(this.code);

  final String code;

  static TextAlignmentEnum fromCode(String code) {
    return TextAlignmentEnum.values.firstWhere((e) => e.code == code);
  }
}