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
      final prompt = generatePromptTranslate(
        text,
        to.nativeName,
        from.nativeName,
      );
      
      final messages = [AiMessage(content: prompt, role: AiRole.user)];
      
      await for (String result in aiGenerateStreamWithoutRef(messages, regenerate: false)) {
        yield result;
      }
    } catch (e) {
      yield L10n.of(navigatorKey.currentContext!).translateError + e.toString();
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
