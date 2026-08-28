enum AiPanelWidthRatio {
  half('half', 0.5),
  third('third', 1 / 3);

  const AiPanelWidthRatio(this.code, this.factor);

  final String code;
  final double factor;

  static AiPanelWidthRatio fromCode(String code) {
    return values.firstWhere(
      (value) => value.code == code,
      orElse: () => AiPanelWidthRatio.half,
    );
  }
}
