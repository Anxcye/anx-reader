import 'dart:async';
import 'dart:convert';

import 'package:anx_reader/service/ai/ai_client.dart';
import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:dio/dio.dart';

class GeminiClient extends AiClient {
  GeminiClient(super.config);

  @override
  Map<String, String> getHeaders() {
    return {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $apiKey',
    };
  }

  @override
  String? extractContent(Map<String, dynamic> json) {
    final delta = json['choices'][0]['delta'];
    return delta['content'];
  }

  @override
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
      List<int> buffer = [];
      String remainingData = '';

      await for (final chunk in stream) {
        buffer.addAll(chunk);

        try {
          final String decodedData = utf8.decode(buffer);
          buffer.clear();

          final String processData = remainingData + decodedData;
          final lines = processData.split('\n');
          remainingData = '';

          for (int i = 0; i < lines.length; i++) {
            final line = lines[i];
            if (line.trim().isEmpty) continue;

            if (i == lines.length - 1 && !line.endsWith(']')) {
              remainingData = line;
              continue;
            }

            if (line.startsWith('data: ')) {
              final data = line.substring(6);
              if (isDone(data)) break;

              try {
                final json = jsonDecode(data);
                final content = extractContent(json);
                if (content != null) {
                  yield content;
                }
              } catch (e) {
                if (i == lines.length - 1) {
                  remainingData = line;
                  continue;
                }
                yield* Stream.error('Parse error: $e\nData: $data');
                continue;
              }
            }
          }
        } catch (e) {
          if (e is FormatException && e.message.contains('Unfinished UTF-8')) {
            continue;
          }
          yield* Stream.error('Decode error: $e');
        }
      }
    } catch (e) {
      AnxLog.severe("geminiGenerateStream error: $e");
      yield* Stream.error('Request failed: $e');
    } finally {
      dio.close();
    }
  }
}

Stream<String> geminiGenerateStream(
  List<Map<String, dynamic>> messages,
  Map<String, String> config,
) {
  final client = GeminiClient(config);
  return client.generateStream(messages);
}
