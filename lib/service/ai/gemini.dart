import 'dart:async';

import 'package:dio/dio.dart';
import 'package:anx_reader/service/ai/ai_dio.dart';
import 'dart:convert';

Stream<String> geminiGenerateStream(
  String prompt,
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
          'Authorization': 'Bearer $apiKey',
        },
        responseType: ResponseType.stream,
        validateStatus: (status) => true,
      ),
      data: {
        'model': model,
        'messages': [
          {'role': 'user', 'content': prompt}
        ],
        'stream': true,
      },
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
            if (data.trim() == '[DONE]') break;

            try {
              final json = jsonDecode(data);
              final delta = json['choices'][0]['delta'];
              final content = delta['content'];
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
    yield* Stream.error('Request failed: $e');
  } finally {
    dio.close();
  }
}
