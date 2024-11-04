import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';

const urlGoogle = 'https://translate.google.com/translate_a/single';

Future<String> googleTranslateService(String text, LangList from, LangList to) async {
    final params = {
      'client': 'gtx',
      'sl': from.code,
      'tl': to.code,
      'dt': 't',
      'q': text,
    };
    final uri = Uri.parse(urlGoogle).replace(queryParameters: params);
    try {
      final response = await Dio().get(uri.toString());
      return response.data[0][0][0];
    } catch (e) {
      AnxLog.severe("Translate Google Error: uri=$uri, error=$e");
      throw Exception(e);
    }
}

