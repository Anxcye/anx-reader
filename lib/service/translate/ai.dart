import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/enums/ai_role.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/ai_message.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/widgets/ai_stream.dart';
import 'package:flutter/material.dart';

class AiTranslateProvider extends TranslateServiceProvider {
  @override
  Widget translate(String text, LangListEnum from, LangListEnum to) {
    return AiStream(
        prompt: generatePromptTranslate(
          text,
          to.nativeName,
          from.nativeName,
        ),
        regenerate: true);
  }

  @override
  Stream<String> translateStream(String text, LangListEnum from, LangListEnum to) async* {
    try {
      // 创建翻译提示词
      final prompt = generatePromptTranslate(
        text,
        to.nativeName,
        from.nativeName,
      );
      
      // 创建AI消息
      final messages = [AiMessage(content: prompt, role: AiRole.user)];
      
      // 使用新的不依赖WidgetRef的AI生成流
      await for (String result in aiGenerateStreamWithoutRef(messages, regenerate: false)) {
        yield result;
      }
    } catch (e) {
      yield 'AI翻译失败: $e';
    }
  }

  @override
  List<ConfigItem> getConfigItems() {
    return [
      ConfigItem(
        key: 'tip',
        label: 'Tip',
        type: ConfigItemType.tip,
        defaultValue:
            L10n.of(navigatorKey.currentContext!).settingsTranslateAiTip,
      ),
    ];
  }

  @override
  Map<String, dynamic> getConfig() {
    return {};
  }

  @override
  Future<void> saveConfig(Map<String, dynamic> config) async {
    return;
  }
}
