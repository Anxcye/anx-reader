import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:dio/dio.dart';

abstract class AiClient {
  final Map<String, String> config;

  AiClient(this.config);

  String get url => config['url'] ?? '';
  String get apiKey => config['api_key'] ?? '';
  String get model => config['model'] ?? '';

  Map<String, String> getHeaders();

  String? extractContent(Map<String, dynamic> json);

  bool isDone(String data) => data.trim() == '[DONE]';

  Map<String, dynamic> generateRequestBody(
      List<Map<String, dynamic>> messages) {
    return {
      'model': model,
      'messages': messages,
      'stream': true,
    };
  }

  FutureOr<String?> processLine(String line) async {
    if (line.trim().isEmpty) return null;

    if (line.startsWith('data: ')) {
      final data = line.substring(6);
      if (isDone(data)) return null;

      try {
        final json = jsonDecode(data);
        final content = extractContent(json);
        return content;
      } catch (e) {
        throw Exception('Parse error: $e\nData: $data');
      }
    }
    return null;
  }

  Stream<String> generateStream(List<Map<String, dynamic>> messages) async* {
    final dio = AiDio.instance.dio;

    try {
      final response = await dio.post(
        url,
        options: Options(
          headers: getHeaders(),
          responseType: ResponseType.stream,
          validateStatus: (status) => true,
        ),
        data: generateRequestBody(messages),
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
          yield* Stream.error('Error: ${response.statusCode} \n $chunk');
          continue;
        }

        final lines = chunk.split('\n');
        for (final line in lines) {
          final content = await processLine(line);
          if (content != null) {
            yield content;
          }
        }
      }
    } catch (e) {
      yield* Stream.error('Request failed: $e');
    } finally {
      dio.close();
    }
  }
}
