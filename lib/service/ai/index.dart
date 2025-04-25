import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/ai_role.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/ai_message.dart';
import 'package:anx_reader/providers/ai_cache_count.dart';
import 'package:anx_reader/service/ai/ai_cache.dart';
import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:anx_reader/service/ai/claude.dart';
import 'package:anx_reader/service/ai/deepseek.dart';
import 'package:anx_reader/service/ai/gemini.dart';
import 'package:anx_reader/service/ai/openai.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

Stream<String> aiGenerateStream(
  WidgetRef ref,
  List<AiMessage> messages, {
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

  AnxLog.info('aiChatGenerateStream: $identifier');

  final messagesStr =
      messages.map((m) => '${m.role.toJson()}: ${m.content}').join('\n');
  final hash = messagesStr.hashCode;
  final aiCache = await AiCache.getAiCache(hash);

  if (aiCache != null && aiCache.isNotEmpty && !regenerate) {
    AnxLog.info('aiChatGenerateStream: cache hit hash: $hash');
    yield aiCache;
    return;
  }

  final formattedMessages = messages
      .map((message) => {
            'role': message.role.toJson(),
            'content': message.content,
          })
      .toList();

  AiDio.instance.newDio();

  switch (identifier) {
    case "openai":
      stream = openAiGenerateStream(formattedMessages, config);
      break;
    case "claude":
      stream = claudeGenerateStream(formattedMessages, config);
      break;
    case "gemini":
      stream = geminiGenerateStream(formattedMessages, config);
      break;
    case "deepseek":
      stream = deepSeekGenerateStream(formattedMessages, config);
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
