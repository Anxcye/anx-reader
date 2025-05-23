import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
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
  List<ConfigItem> getConfigItems() {
    return [
      ConfigItem(
        key: 'tip',
        label: 'Tip',
        type: ConfigItemType.tip,
        defaultValue:
            L10n.of(navigatorKey.currentContext!).settings_translate_ai_tip,
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
