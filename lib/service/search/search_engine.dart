import 'dart:convert';

class SearchEngine {
  final String id;
  final String name;
  final String urlTemplate;
  final bool isBuiltin;

  const SearchEngine({
    required this.id,
    required this.name,
    required this.urlTemplate,
    this.isBuiltin = false,
  });

  static const List<SearchEngine> builtinEngines = [
    SearchEngine(
      id: 'bing',
      name: 'Bing',
      urlTemplate: 'https://www.bing.com/search?q={query}',
      isBuiltin: true,
    ),
    SearchEngine(
      id: 'google',
      name: 'Google',
      urlTemplate: 'https://www.google.com/search?q={query}',
      isBuiltin: true,
    ),
    SearchEngine(
      id: 'duckduckgo',
      name: 'DuckDuckGo',
      urlTemplate: 'https://duckduckgo.com/?q={query}',
      isBuiltin: true,
    ),
    SearchEngine(
      id: 'baidu',
      name: 'Baidu',
      urlTemplate: 'https://www.baidu.com/s?wd={query}',
      isBuiltin: true,
    ),
  ];

  String buildUrl(String query) {
    return urlTemplate.replaceAll('{query}', Uri.encodeQueryComponent(query));
  }

  static bool isValidUrlTemplate(String template) {
    if (!template.contains('{query}')) return false;
    final uri = Uri.tryParse(template.replaceAll('{query}', 'test'));
    if (uri == null) return false;
    return uri.scheme == 'http' || uri.scheme == 'https';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'urlTemplate': urlTemplate,
        'isBuiltin': isBuiltin,
      };

  factory SearchEngine.fromJson(Map<String, dynamic> json) => SearchEngine(
        id: json['id'] as String,
        name: json['name'] as String,
        urlTemplate: json['urlTemplate'] as String,
        isBuiltin: json['isBuiltin'] as bool? ?? false,
      );

  static List<SearchEngine> decodeList(String jsonStr) {
    final List<dynamic> decoded = jsonDecode(jsonStr);
    return decoded
        .map((e) => SearchEngine.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static String encodeList(List<SearchEngine> engines) {
    return jsonEncode(engines.map((e) => e.toJson()).toList());
  }

  static String generateId() {
    return DateTime.now().millisecondsSinceEpoch.toRadixString(36);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is SearchEngine &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;
}
