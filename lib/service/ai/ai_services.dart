import 'package:anx_reader/utils/env_var.dart';

class AiServiceOption {
  const AiServiceOption({
    required this.identifier,
    required this.title,
    required this.logo,
    required this.defaultUrl,
    required this.defaultApiKey,
    required this.defaultModel,
  });

  final String identifier;
  final String title;
  final String logo;
  final String defaultUrl;
  final String defaultApiKey;
  final String defaultModel;
}

List<AiServiceOption> buildDefaultAiServices() {
  return [
    !EnvVar.enableOpenAiConfig
        ? AiServiceOption(
            identifier: 'openai',
            title: '通用',
            logo: 'assets/images/commonAi.png',
            defaultUrl:
                'https://dashscope.aliyuncs.com/compatible-mode/v1/chat/completions',
            defaultApiKey: 'YOUR_API_KEY',
            defaultModel: 'qwen-long',
          )
        : AiServiceOption(
            identifier: 'openai',
            title: 'OpenAI',
            logo: 'assets/images/openai.png',
            defaultUrl: 'https://api.openai.com/v1/chat/completions',
            defaultApiKey: 'YOUR_API_KEY',
            defaultModel: 'gpt-4o-mini',
          ),
    AiServiceOption(
      identifier: 'claude',
      title: 'Claude',
      logo: 'assets/images/claude.png',
      defaultUrl: 'https://api.anthropic.com/v1/messages',
      defaultApiKey: 'YOUR_API_KEY',
      defaultModel: 'claude-3-5-sonnet-20240620',
    ),
    AiServiceOption(
      identifier: 'gemini',
      title: 'Gemini',
      logo: 'assets/images/gemini.png',
      defaultUrl: 'https://generativelanguage.googleapis.com',
      defaultApiKey: 'YOUR_API_KEY',
      defaultModel: 'gemini-2.5-flash',
    ),
    AiServiceOption(
      identifier: 'deepseek',
      title: 'DeepSeek',
      logo: 'assets/images/deepseek.png',
      defaultUrl: 'https://api.deepseek.com',
      defaultApiKey: 'YOUR_API_KEY',
      defaultModel: 'deepseek-v4-flash',
    ),
    AiServiceOption(
      identifier: 'openrouter',
      title: 'OpenRouter',
      logo: 'assets/images/openrouter.png',
      defaultUrl: 'https://openrouter.ai/api/v1/chat/completions',
      defaultApiKey: 'YOUR_API_KEY',
      defaultModel: 'gpt-4o-mini',
    ),
  ];
}
