import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/providers/ai_cache_count.dart';
import 'package:anx_reader/service/ai/ai_cache.dart';
import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:anx_reader/service/ai/claude.dart';
import 'package:anx_reader/service/ai/deepseek.dart';
import 'package:anx_reader/service/ai/gemini.dart';
import 'package:anx_reader/service/ai/openai.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:path/path.dart';

Stream<String> aiGenerateStream(
  WidgetRef ref,
  String prompt, {
  String? identifier,
  Map<String, String>? config,
  bool regenerate = false,
}) async* {
  identifier ??= Prefs().selectedAiService;
  config ??= Prefs().getAiConfig(identifier);
  String buffer = '';
  Stream<String> stream;

  final url = config['url'];
  if (url == null || url.isEmpty) {
    yield L10n.of(navigatorKey.currentContext!).ai_service_not_configured;
    return;
  }

  
  AnxLog.info('aiGenerateStream: $identifier');

  final hash = prompt.hashCode;
  final aiCache = await AiCache.getAiCache(hash);

  if (aiCache != null && aiCache.isNotEmpty && !regenerate) {
    AnxLog.info('aiGenerateStream: cache hit hash: $hash');
    yield aiCache;
    return;
  }

  switch (identifier) {
    case "openai":
      stream = openAiGenerateStream(prompt, config);
      break;
    case "claude":
      stream = claudeGenerateStream(prompt, config);
      break;
    case "gemini":
      stream = geminiGenerateStream(prompt, config);
      break;
    case "deepseek":
      stream = deepSeekGenerateStream(prompt, config);
      break;
    default:
      throw Exception("Invalid AI identifier");
  }

  await for (final chunk in stream) {
    buffer += chunk;
    yield buffer;
  }
  AiDio.instance.cancel();
  await AiCache.setAiCache(hash, buffer, identifier);
  ref.read(aiCacheCountProvider.notifier).refresh();
}
  
Future<String> aiGenerate(
  WidgetRef ref,
  String prompt, {
  String? identifier,
  Map<String, String>? config,
}) async {
  final buffer = StringBuffer();
  await for (final chunk
      in aiGenerateStream(ref, prompt, identifier: identifier, config: config)) {
    buffer.write(chunk);
  }
  return buffer.toString();
}
