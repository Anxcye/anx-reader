import 'package:anx_reader/service/ai/ai_client.dart';

class OpenAiClient extends AiClient {
  OpenAiClient(super.config);

  @override
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  @override
  String? extractContent(Map<String, dynamic> json) {
    final delta = json['choices'][0]['delta'];
    return delta['content'];
  }
}

Stream<String> openAiGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) {
  final client = OpenAiClient(config);
  return client.generateStream(messages);
}
