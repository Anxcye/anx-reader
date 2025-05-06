import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';

const urlDeepL = 'https://api-free.deepl.com/v2/translate';

class DeepLTranslateProvider implements TranslateServiceProvider {
  @override
  Stream<String> translate(
      String text, LangListEnum from, LangListEnum to) async* {
    try {
      final config = getConfig();

      if (config['api_key'].toString().isEmpty) {
        yield* Stream.error(Exception('Invalid DeepL API key'));
        return;
      }

      yield "...";

      final Map<String, dynamic> params = {
        'text': text,
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
        urlDeepL,
        data: params,
        options: Options(
          headers: headers,
          validateStatus: (status) => true,
        ),
      );

      if (response.statusCode != 200) {
        yield* Stream.error(Exception('DeepL API错误: ${response.data}'));
        return;
      }

      final responseData = response.data;
      if (responseData['translations'] != null &&
          responseData['translations'].isNotEmpty) {
        yield responseData['translations'][0]['text'];
      } else {
        yield* Stream.error(Exception('DeepL返回结果格式错误'));
      }
    } catch (e) {
      AnxLog.severe("DeepL翻译错误: $e");
      yield* Stream.error(Exception(e));
    }
  }

  String _mapLanguageCode(String isoCode) {
    final Map<String, String> codeMap = {
      'zh': 'ZH',
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

    return codeMap[isoCode.toLowerCase()] ?? isoCode.toUpperCase();
  }

  @override
  List<ConfigItem> getConfigItems() {
    return [
      ConfigItem(
        key: 'api_key',
        label: 'DeepL API Key',
        description: 'Please enter your DeepL API key, which can be obtained from the DeepL developer page',
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
          'use_free_api': true,
          'formality': 'default',
          'use_proxy': false,
          'proxy_url': '',
        };
  }

  @override
  Future<void> saveConfig(Map<String, dynamic> config) async {
    Prefs().saveTranslateServiceConfig(TranslateService.deepl, config);
  }
}
