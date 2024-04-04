class BookStyle {
  double fontSize;
  String fontFamily;
  double lineHeight;
  double letterSpacing;
  double wordSpacing;
  double paragraphSpacing;
  double sideMargin;
  double topMargin;
  double bottomMargin;

  BookStyle({
    this.fontSize = 5.0,
    this.fontFamily = 'Arial',
    this.lineHeight = 2,
    this.letterSpacing = 2,
    this.wordSpacing = 2,
    this.paragraphSpacing = 0.55,
    this.sideMargin = 3.0,
    this.topMargin = 5,
    this.bottomMargin = 5,
  });

  BookStyle copyWith({
    double? fontSize,
    String? fontFamily,
    double? lineHeight,
    double? letterSpacing,
    double? wordSpacing,
    double? paragraphSpacing,
    double? sideMargin,
    double? topMargin,
    double? bottomMargin,
  }) {
    return BookStyle(
      fontSize: fontSize ?? this.fontSize,
      fontFamily: fontFamily ?? this.fontFamily,
      lineHeight: lineHeight ?? this.lineHeight,
      letterSpacing: letterSpacing ?? this.letterSpacing,
      wordSpacing: wordSpacing ?? this.wordSpacing,
      paragraphSpacing: paragraphSpacing ?? this.paragraphSpacing,
      sideMargin: sideMargin ?? this.sideMargin,
      topMargin: topMargin ?? this.topMargin,
      bottomMargin: bottomMargin ?? this.bottomMargin,
    );
  }

  Map<String, Object> toMap() {
    return {
      'fontSize': fontSize,
      'fontFamily': fontFamily,
      'lineHeight': lineHeight,
      'letterSpacing': letterSpacing,
      'wordSpacing': wordSpacing,
      'paragraphSpacing': paragraphSpacing,
      'sideMargin': sideMargin,
      'topMargin': topMargin,
      'bottomMargin': bottomMargin,
    };
  }

}