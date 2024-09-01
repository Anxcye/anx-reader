import 'dart:convert';

class FontModel {
  final String label;
  final String name;
  final String path;

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
      "path": "$path"
    }
    ''';
  }

  static FontModel fromJson(String fontJson) {
    final Map<String, dynamic> json = jsonDecode(fontJson);
    return FontModel(
      label: json['label'],
      name: json['name'],
      path: json['path'],
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is FontModel &&
          runtimeType == other.runtimeType &&
          name == other.name &&
          path == other.path;

  @override
  int get hashCode => name.hashCode ^ path.hashCode;
}
