import 'package:anx_reader/service/ai/claude_client.dart';
import 'package:anx_reader/service/ai/deepseek_client.dart';
import 'package:anx_reader/service/ai/gemini_client.dart';
import 'package:anx_reader/service/ai/openai_client.dart';

class AiFactory {
  static Stream<String> generateStream(
    String identifier,
    List<Map<String, dynamic>> messages,
    Map<String, String> config,
  ) {
    switch (identifier) {
      case "openai":
        return openAiGenerateStream(messages, config);
      case "claude":
        return claudeGenerateStream(messages, config);
      case "gemini":
        return geminiGenerateStream(messages, config);
      case "deepseek":
        return deepSeekGenerateStream(messages, config);
      default:
        throw Exception("Invalid AI identifier: $identifier");
    }
  }
}
