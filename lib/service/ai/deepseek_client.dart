import 'dart:async';

import 'package:anx_reader/service/ai/ai_client.dart';

class DeepSeekClient extends AiClient {
  DeepSeekClient(super.config);

  @override
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  @override
  String? extractContent(Map<String, dynamic> json) {
    String? content = json['choices'][0]['delta']['content'];
    content ??= json['choices'][0]['delta']['reasoning_content'];
    return content;
  }
}

Stream<String> deepSeekGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) {
  final client = DeepSeekClient(config);
  return client.generateStream(messages);
}
