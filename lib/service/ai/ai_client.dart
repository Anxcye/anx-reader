import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

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
    final trimmed = line.trim();
    if (trimmed.isEmpty) return null;

    if (trimmed.startsWith('data:')) {
      final data = trimmed.substring(5).trim();
      if (isDone(data) || data.isEmpty) return null;

      try {
        final json = jsonDecode(data) as Map<String, dynamic>;
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

      final byteStream = response.data.stream.cast<List<int>>();
      final utf8Stream = utf8.decoder.bind(byteStream);
      final lineStream = const LineSplitter().bind(utf8Stream);

      await for (final line in lineStream) {
        if (response.statusCode != 200) {
          yield* Stream.error('Error: ${response.statusCode} \n $line');
          continue;
        }

        final content = await processLine(line);
        if (content != null) {
          yield content;
        }
      }
    } catch (e, s) {
      if (kDebugMode) {
        print('$e $s');
      }
      yield* Stream.error('Request failed: $e');
    } finally {
      dio.close();
    }
  }
}
