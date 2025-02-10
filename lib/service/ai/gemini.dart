import 'dart:async';

import 'package:flutter_gemini/flutter_gemini.dart';

Stream<String> geminiGenerateStream(
  String prompt,
  Map<String, String> config,
) async* {
  final apiKey = config['api_key'];
  if (apiKey == null) {
    throw Exception('api_key is required');
  }
  Gemini.init(apiKey: apiKey);

  try {
    await for (final value in Gemini.instance.promptStream(parts: [
      Part.text(prompt),
    ])) {
      if (value != null) {
        yield value.output ?? '';
      }
    }
  } catch (e) {
    yield* Stream.error('Request failed: $e');
  }
}
