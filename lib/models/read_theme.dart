import 'dart:core';

class ReadTheme{
  int? id;
  String backgroundColor;
  String textColor;
  String backgroundImagePath;

  ReadTheme({
    this.id,
    required this.backgroundColor,
    required this.textColor,
    required this.backgroundImagePath
  });

  Map<String, Object?> toMap(){
    return {
      'background_color': backgroundColor,
      'text_color': textColor,
      'background_image_path': backgroundImagePath
    };
  }



}