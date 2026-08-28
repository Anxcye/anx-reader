import 'dart:convert';
import 'package:http/http.dart' as http;

/// Fetches the list of available model IDs from an OpenAI-compatible /models endpoint.
///
/// Returns a sorted list of model ID strings on success, or throws an exception
/// with a descriptive message on failure.
Future<List<String>> fetchAiModels({
  required String url,
  required String apiKey,
  Duration timeout = const Duration(seconds: 10),
}) async {
  final uri = Uri.parse(url.trim());
  final segments = uri.pathSegments.toList();
  while (segments.isNotEmpty &&
      const {'chat', 'completions', 'responses'}.contains(segments.last)) {
    segments.removeLast();
  }
  final modelsUrl = uri
      .replace(pathSegments: [...segments, 'models'], query: null).toString();

  final request = http.get(
    Uri.parse(modelsUrl),
    headers: {
      if (apiKey.trim().isNotEmpty) 'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
  );
  final response =
      timeout == Duration.zero ? await request : await request.timeout(timeout);

  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  final data = jsonDecode(response.body);
  final List<dynamic> models = data['data'] ?? [];

  if (models.isEmpty) {
    return [];
  }

  final ids =
      models.map<String>((m) => (m['id'] ?? m.toString()) as String).toList();
  ids.sort();
  return ids;
}
