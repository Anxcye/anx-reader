import 'dart:async';

import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'dart:convert';

Stream<String> claudeGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) async* {
  final url = config['url'];
  final apiKey = config['api_key'];
  final model = config['model'];
  final dio = AiDio.instance.dio;

  try {
    final response = await dio.post(
      url!,
      options: Options(
        headers: {
          'Content-Type': 'application/json',
          'x-api-key': apiKey,
          'anthropic-version': '2023-06-01',
        },
        responseType: ResponseType.stream,
        validateStatus: (status) => true,
      ),
      data: {
        'model': model,
        'max_tokens': 2048,
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

      for (final line in chunk.split('\n')) {
        if (line.isEmpty || line.startsWith('event: ')) continue;
        final data = line.startsWith('data: ') ? line.substring(6) : line;
        try {
          final json = jsonDecode(data);

          if (json['type'] == 'content_block_delta') {
            final text = json['delta']['text'];
            if (text != null && text.isNotEmpty) {
              yield text;
            }
          }
        } catch (e) {
          yield* Stream.error('Parse error: $e\nData: $data');
          continue;
        }
      }
    }
  } catch (e) {
    if (kDebugMode) {
      throw Exception(e);
    } else {
      yield* Stream.error('Request failed: $e');
    }
  } finally {
    dio.close();
  }
}
