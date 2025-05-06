import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';

const urlGoogle = 'https://translate.google.com/translate_a/single';

class GoogleTranslateProvider implements TranslateServiceProvider {
  @override
  Stream<String> translate(
      String text, LangListEnum from, LangListEnum to) async* {
    final params = {
      'client': 'gtx',
      'sl': from.code,
      'tl': to.code,
      'dt': 't',
      'q': text,
    };
    final uri = Uri.parse(urlGoogle).replace(queryParameters: params);
    try {
      final response = await Dio().get(
        uri.toString(),
        options: Options(
          validateStatus: (status) => true,
        ),
      );
      if (response.statusCode != 200) {
        yield* Stream.error(Exception(response.data));
        return;
      }
      yield response.data[0][0][0];
    } catch (e) {
      AnxLog.severe("Translate Google Error: uri=$uri, error=$e");
      yield* Stream.error(Exception(e));
    }
  }
}
