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

  BookStyle({
    this.fontSize = 120.0,
    this.fontFamily = 'Arial',
    this.lineHeight = 1.8,
    this.letterSpacing = 2.0,
    this.wordSpacing = 2.0,
    this.paragraphSpacing = 15.0,
    this.sideMargin = 50.0,
    this.topMargin = 70.0,
    this.bottomMargin = 60.0,
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
      "bottomMargin": $bottomMargin
    }
    ''';
  }

  factory BookStyle.fromJson(String json) {
    Map<String, dynamic> data = jsonDecode(json);
    return BookStyle(
      fontSize: data['fontSize'] is String
          ? double.parse(data['fontSize'])
          : data['fontSize'],
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
      paragraphSpacing: data['paragraphSpacing'] is String
          ? double.parse(data['paragraphSpacing'])
          : data['paragraphSpacing'],
      sideMargin: data['sideMargin'] is String
          ? double.parse(data['sideMargin'])
          : data['sideMargin'],
      topMargin: data['topMargin'] is String
          ? double.parse(data['topMargin'])
          : data['topMargin'],
      bottomMargin: data['bottomMargin'] is String
          ? double.parse(data['bottomMargin'])
          : data['bottomMargin'],
    );
  }
}
