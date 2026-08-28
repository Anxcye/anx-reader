import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/service/config/config_item.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

const _deeplApiUrl = 'https://api-free.deepl.com/v2/translate';

class DeepLTranslateProvider extends TranslateServiceProvider {
  @override
  TranslateService get service => TranslateService.deepl;

  /// DeepL uses uppercase language codes (e.g., ZH, EN, JA).
  @override
  String mapLanguageCode(LangListEnum lang) {
    const Map<String, String> codeMap = {
      'zh-CN': 'ZH',
      'zh-TW': 'ZH',
      'en': 'EN',
      'ja': 'JA',
      'de': 'DE',
      'fr': 'FR',
      'es': 'ES',
      'it': 'IT',
      'nl': 'NL',
      'pl': 'PL',
      'pt': 'PT',
      'ru': 'RU',
    };
    return codeMap[lang.code] ?? lang.code.toUpperCase();
  }

  @override
  String getLabel(BuildContext context) => L10n.of(context).translateDeepL;

  @override
  Widget translate(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  }) {
    return convertStreamToWidget(
      translateStream(text, from, to, contextText: contextText),
    );
  }

  @override
  Stream<String> translateStream(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  }) async* {
    try {
      final config = getConfig();

      if (config['api_key'].toString().isEmpty) {
        yield* Stream.error(Exception('Invalid DeepL API key'));
        return;
      }

      yield "...";

      final Map<String, dynamic> params = {
        'text': [text],
        'target_lang': mapLanguageCode(to),
      };

      if (from != LangListEnum.auto) {
        params['source_lang'] = mapLanguageCode(from);
      }

      final headers = {
        'Authorization': 'DeepL-Auth-Key ${config['api_key']}',
        'Content-Type': 'application/json',
      };

      final response = await Dio().post(
        config['api_url'] ?? _deeplApiUrl,
        data: params,
        options: Options(
          headers: headers,
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != 200) {
        yield* Stream.error(Exception('DeepL API error: ${response.data}'));
        return;
      }

      final responseData = response.data;
      if (responseData['translations'] != null &&
          responseData['translations'].isNotEmpty) {
        yield responseData['translations'][0]['text'];
      } else {
        yield* Stream.error(
            Exception('Deepl returned unexpected data: ${response.data}'));
      }
    } catch (e) {
      AnxLog.severe('DeepL translation error: $e');
      yield* Stream.error(Exception(e));
    }
  }

  @override
  List<ConfigItem> getConfigItems(BuildContext context) {
    return [
      ConfigItem(
        key: 'tip',
        label: L10n.of(context).translateTip,
        type: ConfigItemType.tip,
        defaultValue: L10n.of(context).translateDeepLHelpText,
        link: 'https://anx.anxcye.com/docs/translate/deepl',
      ),
      ConfigItem(
        key: 'api_url',
        label: 'DeepL API URL',
        type: ConfigItemType.text,
        defaultValue: _deeplApiUrl,
      ),
      ConfigItem(
        key: 'api_key',
        label: 'DeepL API Key',
        description: L10n.of(context).deeplKeyTip,
        type: ConfigItemType.password,
        defaultValue: '',
      ),
    ];
  }

  @override
  Map<String, dynamic> getConfig() {
    final config = Prefs().getTranslateServiceConfig(service);
    return config ?? {'api_key': '', 'api_url': _deeplApiUrl};
  }

  @override
  void saveConfig(Map<String, dynamic> config) {
    Prefs().saveTranslateServiceConfig(service, config);
  }
}
