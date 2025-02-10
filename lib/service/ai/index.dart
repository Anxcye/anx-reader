import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/service/ai/claude.dart';
import 'package:anx_reader/service/ai/openai.dart';

Stream<String> aiGenerateStream(
  String prompt, {
  String? identifier,
  Map<String, String>? config,
}) async* {
  identifier ??= Prefs().selectedAiService;
  config ??= Prefs().getAiConfig(identifier);
  String buffer = '';
  Stream<String> stream;

  switch (identifier) {
    case "openai":
      stream = openAiGenerateStream(prompt, config);
      break;
    case "claude":
      stream = claudeGenerateStream(prompt, config);
      break;
    default:
      throw Exception("Invalid AI identifier");
  }


  await for (final chunk in stream) {
    buffer += chunk;
    yield buffer;
  }
}

Future<String> aiGenerate(
  String prompt, {
  String? identifier,
  Map<String, String>? config,
}) async {
  final buffer = StringBuffer();
  await for (final chunk
      in aiGenerateStream(prompt, identifier: identifier, config: config)) {
    buffer.write(chunk);
  }
  return buffer.toString();
}
