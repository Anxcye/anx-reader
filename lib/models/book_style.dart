import 'dart:convert';

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
  double indent;

  BookStyle({
    this.fontSize = 1.0,
    this.fontFamily = 'Arial',
    this.lineHeight = 1.8,
    this.letterSpacing = 2.0,
    this.wordSpacing = 2.0,
    this.paragraphSpacing = 1.0,
    this.sideMargin = 6.0,
    this.topMargin = 80.0,
    this.bottomMargin = 40.0,
    this.indent = 0,
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
    double? indent,
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
      indent: indent ?? this.indent,
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
      'indent': indent,
    };
  }

  String toJson() {
    return '''
    {
      "fontSize": $fontSize,
      "fontFamily": "$fontFamily",
      "lineHeight": $lineHeight,
      "letterSpacing": $letterSpacing,
      "wordSpacing": $wordSpacing,
      "paragraphSpacing": $paragraphSpacing,
      "sideMargin": $sideMargin,
      "topMargin": $topMargin,
      "bottomMargin": $bottomMargin,
      "indent": $indent
    }
    ''';
  }

  factory BookStyle.fromJson(String json) {
    Map<String, dynamic> data = jsonDecode(json);
    double fontsSize = data['fontSize'] is String
        ? double.parse(data['fontSize'])
        : data['fontSize'];
    double paragraphSpacing = data['paragraphSpacing'] is String
        ? double.parse(data['paragraphSpacing'])
        : data['paragraphSpacing'];

    if (fontsSize > 2 || fontsSize < 0.5) {
      fontsSize = 1;
    }
    if (paragraphSpacing > 3 || paragraphSpacing < 0) {
      paragraphSpacing = 1.5;
    }

    return BookStyle(
      fontSize: fontsSize,
      fontFamily: data['fontFamily'],
      lineHeight: data['lineHeight'] is String
          ? double.parse(data['lineHeight'])
          : data['lineHeight'],
      letterSpacing: data['letterSpacing'] is String
          ? double.parse(data['letterSpacing'])
          : data['letterSpacing'],
      wordSpacing: data['wordSpacing'] is String
          ? double.parse(data['wordSpacing'])
          : data['wordSpacing'],
      paragraphSpacing: paragraphSpacing,
      sideMargin: data['sideMargin'] is String
          ? double.parse(data['sideMargin'])
          : data['sideMargin'],
      topMargin: data['topMargin'] is String
          ? double.parse(data['topMargin'])
          : data['topMargin'],
      bottomMargin: data['bottomMargin'] is String
          ? double.parse(data['bottomMargin'])
          : data['bottomMargin'],
      indent: data['indent'] == null
          ? 0
          : data['indent'] is String
              ? double.parse(data['indent'])
              : data['indent'],
    );
  }
}
