import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/service/ai/ai_client.dart';

class ClaudeClient extends AiClient {
  ClaudeClient(super.config);

  @override
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'x-api-key': apiKey,
      'anthropic-version': '2023-06-01',
    };
  }

  @override
  String? extractContent(Map<String, dynamic> json) {
    if (json['type'] == 'content_block_delta') {
      return json['delta']['text'];
    }
    return null;
  }

  @override
  bool isDone(String data) {
    return false;
  }

  @override
  FutureOr<String?> processLine(String line) async {
    if (line.isEmpty || line.startsWith('event: ')) return null;

    final data = line.startsWith('data: ') ? line.substring(6) : line;
    try {
      final json = jsonDecode(data);
      return extractContent(json);
    } catch (e) {
      throw Exception('Parse error: $e\nData: $data');
    }
  }
}

Stream<String> claudeGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) {
  final client = ClaudeClient(config);
  return client.generateStream(messages);
}
