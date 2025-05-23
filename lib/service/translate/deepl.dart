import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';

String deeplUrl = 'https://api-free.deepl.com/v2/translate';

String getDeepLUrl(Map<String, dynamic> config) {
  return config['api_url'] ?? deeplUrl;
}

class DeepLTranslateProvider extends TranslateServiceProvider {
  @override
  Widget translate(String text, LangListEnum from, LangListEnum to) {
    return convertStreamToWidget(translateStream(text, from, to));
  }

  Stream<String> translateStream(
      String text, LangListEnum from, LangListEnum to) async* {
    try {
      final config = getConfig();

      if (config['api_key'].toString().isEmpty) {
        yield* Stream.error(Exception('Invalid DeepL API key'));
        return;
      }

      yield "...";

      final Map<String, dynamic> params = {
        'text': [text],
        'target_lang': _mapLanguageCode(to.code),
      };

      if (from != LangListEnum.auto) {
        params['source_lang'] = _mapLanguageCode(from.code);
      }
      var dio = Dio();

      final headers = {
        'Authorization': 'DeepL-Auth-Key ${config['api_key']}',
        'Content-Type': 'application/json',
      };

      final response = await dio.post(
        getDeepLUrl(config),
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
      AnxLog.severe(
          "Deepl ${L10n.of(navigatorKey.currentContext!).translate_error}: $e");
      yield* Stream.error(Exception(e));
    }
  }

  String _mapLanguageCode(String isoCode) {
    final Map<String, String> codeMap = {
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

    return codeMap[isoCode] ?? isoCode.toUpperCase();
  }

  @override
  List<ConfigItem> getConfigItems() {
    return [
      ConfigItem(
        key: 'api_url',
        label: 'DeepL API URL',
        type: ConfigItemType.text,
        defaultValue: deeplUrl,
      ),
      ConfigItem(
        key: 'api_key',
        label: 'DeepL API Key',
        description: L10n.of(navigatorKey.currentContext!).deepl_key_tip,
        type: ConfigItemType.password,
        defaultValue: '',
      ),
    ];
  }

  @override
  Map<String, dynamic> getConfig() {
    final config = Prefs().getTranslateServiceConfig(TranslateService.deepl);

    return config ??
        {
          'api_key': '',
          'api_url': deeplUrl,
        };
  }

  @override
  Future<void> saveConfig(Map<String, dynamic> config) async {
    Prefs().saveTranslateServiceConfig(TranslateService.deepl, config);
  }
}
