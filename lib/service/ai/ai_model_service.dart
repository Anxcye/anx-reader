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
  final baseUrl = url.trim();
  final modelsUrl =
      baseUrl.endsWith('/') ? '${baseUrl}models' : '$baseUrl/models';

  final response = await http.get(
    Uri.parse(modelsUrl),
    headers: {
      'Authorization': 'Bearer $apiKey',
      'Content-Type': 'application/json',
    },
  ).timeout(timeout);

  if (response.statusCode != 200) {
    throw Exception('HTTP ${response.statusCode}: ${response.body}');
  }

  final data = jsonDecode(response.body);
  final List<dynamic> models = data['data'] ?? [];

  if (models.isEmpty) {
    return [];
  }

  final ids = models.map<String>((m) {
    if (m is Map) {
      final id = m['id'];
      if (id != null && id.toString().trim().isNotEmpty) {
        return id.toString();
      }
    }
    final fallback = m.toString();
    if (fallback.isEmpty || fallback == 'null') {
      throw FormatException('Model entry is missing a usable id');
    }
    return fallback;
  }).toList();
  ids.sort();
  return ids;
}
