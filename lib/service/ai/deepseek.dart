import 'dart:async';
import 'dart:typed_data';

import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:dio/dio.dart';
import 'dart:convert';

Stream<String> deepSeekGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) async* {
  final url = config['url'];
  final apiKey = config['api_key'];
  final model = config['model'];
  final dio = AiDio.instance.dio;
  Response? response;

  try {
    response = await dio.post(
      url!,
      options: Options(headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $apiKey',
      }, responseType: ResponseType.stream, validateStatus: (status) => true),
      data: {
        'model': model,
        'messages': messages,
        'stream': true,
      },
    );

    final stream = response.data.stream;
    await for (final chunk in stream.transform(
      StreamTransformer<Uint8List, String>.fromHandlers(
        handleData: (Uint8List data, EventSink<String> sink) {
          sink.add(utf8.decode(data));
        },
      ),
    )) {
      if (response.statusCode != 200) {
        yield* Stream.error('error ${response.statusCode} \n $chunk');
        continue;
      }

      final lines = chunk.split('\n');
      for (final line in lines) {
        if (line.trim().isEmpty) continue;

        if (line.startsWith('data: ')) {
          final data = line.substring(6);
          if (data.trim() == '[DONE]') break;

          try {
            final json = jsonDecode(data);
            String? content = json['choices'][0]['delta']['content'];
            content ??= json['choices'][0]['delta']['reasoning_content'];
            if (content != null) {
              yield content;
            }
          } catch (e) {
            yield* Stream.error('Parse error: $e\nData: $data');
            continue;
          }
        }
      }
    }
  } catch (e) {
    yield* Stream.error('Request failed: $e');
  } finally {
    dio.close();
  }
}
