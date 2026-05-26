import 'package:anx_reader/enums/ai_thinking_mode.dart';

const deepSeekDefaultBaseUrl = 'https://api.deepseek.com';
const deepSeekDefaultModel = 'deepseek-v4-flash';
const deepSeekProModel = 'deepseek-v4-pro';

bool isDeepSeekProvider({
  required String identifier,
  required String model,
  String? baseUrl,
}) {
  final lowerIdentifier = identifier.toLowerCase();
  final lowerModel = model.toLowerCase();
  final lowerBaseUrl = (baseUrl ?? '').toLowerCase();

  return lowerIdentifier == 'deepseek' ||
      lowerBaseUrl.contains('api.deepseek.com') ||
      lowerModel.startsWith('deepseek-');
}

Map<String, dynamic>? deepSeekThinkingExtraBody(AiThinkingMode mode) {
  return switch (mode) {
    AiThinkingMode.auto => null,
    AiThinkingMode.enabled => const {
        'thinking': {'type': 'enabled'},
      },
    AiThinkingMode.disabled => const {
        'thinking': {'type': 'disabled'},
      },
  };
}
