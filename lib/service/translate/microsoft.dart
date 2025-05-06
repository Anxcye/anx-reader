import 'dart:convert';

import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';

const urlMicrosoft =
    'https://api-edge.cognitive.microsofttranslator.com/translate';
const urlMicrosoftAuth = 'https://edge.microsoft.com/translate/auth';

class MicrosoftTranslateProvider implements TranslateServiceProvider {
  @override
  Stream<String> translate(
      String text, LangListEnum from, LangListEnum to) async* {
    try {
      yield "...";
      final token = await getMicrosoftKey();

      final params = {
        'api-version': '3.0',
        'from': from == LangListEnum.auto ? '' : from.code,
        'to': to.code,
      };
      final body = [
        {'Text': text},
      ];
      final uri = Uri.parse(urlMicrosoft).replace(queryParameters: params);
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      };

      final response = await Dio()
          .post(uri.toString(), data: body, options: Options(headers: headers));
      yield response.data[0]['translations'][0]['text'];
    } catch (e) {
      AnxLog.severe("Translate Microsoft Error: error=$e");
      yield* Stream.error(Exception(e));
    }
  }

  @override
  List<ConfigItem> getConfigItems() {
    return [];
  }

  @override
  Map<String, dynamic> getConfig() {
    return {};
  }

  @override
  Future<void> saveConfig(Map<String, dynamic> config) async {
    return;
  }

  Future<String> getMicrosoftKey() async {
    String microsoftKey = '';
    num microsoftKeyExpired = 0;
    if (microsoftKey.isNotEmpty &&
        microsoftKeyExpired > DateTime.now().millisecondsSinceEpoch ~/ 1000) {
      return microsoftKey;
    }
    final response = await Dio().get(urlMicrosoftAuth);
    microsoftKey = response.data;
    // parse jwt token
    String jwt = microsoftKey.split('.')[1];
    jwt = jwt.replaceAll('-', '+').replaceAll('_', '/');
    jwt = jwt.padRight(jwt.length + (4 - jwt.length % 4) % 4, '=');

    final jwtJson = jsonDecode(utf8.decode(base64Url.decode(jwt)));
    microsoftKeyExpired = jwtJson['exp'];
    return microsoftKey;
  }
}
