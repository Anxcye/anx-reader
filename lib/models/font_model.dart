import 'dart:convert';

import 'package:anx_reader/service/book_player/book_player_server.dart';

class FontModel {
  final String label;
  final String name;
  String path;

  FontModel({
    required this.label,
    required this.name,
    required this.path,
  });

  String toJson() {
    return '''
    {
      "label": "$label",
      "name": "$name",
      "path": "${path.split('/').last}"
    }
    ''';
  }

  String get litePath => path.split('/').last;

  static FontModel fromJson(String fontJson) {
    final Map<String, dynamic> json = jsonDecode(fontJson);
    return FontModel(
      label: json['label'],
      name: json['name'],
      path: 'http://127.0.0.1:${Server().port}/fonts/${json['path']}',
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontModel &&
          runtimeType == other.runtimeType &&
          litePath == other.litePath;

  @override
  int get hashCode => name.hashCode ^ path.hashCode;
}
