import 'dart:convert';

import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';

const urlMicrosoft =
    'https://api-edge.cognitive.microsofttranslator.com/translate';
const urlMicrosoftAuth = 'https://edge.microsoft.com/translate/auth';



Future<String> microsoftTranslateService(
    String text, LangList from, LangList to) async {
  final token = await getMicrosoftKey();
  final params = {
    'api-version': '3.0',
    'from': from == LangList.auto ? '' : from.code,
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
  try {
    final response = await Dio()
        .post(uri.toString(), data: body, options: Options(headers: headers));
    return response.data[0]['translations'][0]['text'];
  } catch (e) {
    AnxLog.severe("Translate Microsoft Error: uri=$uri, error=$e");
    throw Exception(e);
  }
}

String microsoftKey = '';
num microsoftKeyExpired = 0;

Future<String> getMicrosoftKey() async {
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