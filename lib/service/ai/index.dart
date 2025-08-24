import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/enums/ai_role.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/main.dart';
import 'package:anx_reader/models/ai_message.dart';
import 'package:anx_reader/service/ai/ai_cache.dart';
import 'package:anx_reader/service/ai/ai_dio.dart';
import 'package:anx_reader/service/ai/ai_factory.dart';
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

  final url = config['url'];
  if (url == null || url.isEmpty) {
    yield L10n.of(navigatorKey.currentContext!).aiServiceNotConfigured;
    return;
  }

  AnxLog.info('aiGenerateStream: $identifier');

  final messagesStr =
      messages.map((m) => '${m.role.toJson()}: ${m.content}').join('\n');
  final hash = messagesStr.hashCode;
  final aiCache = await AiCache.getAiCache(hash);

  if (aiCache != null && aiCache.isNotEmpty && !regenerate) {
    AnxLog.info('aiGenerateStream: Cache hit hash: $hash');
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

  try {
    Stream<String> stream =
        AiFactory.generateStream(identifier, formattedMessages, config);

    await for (final chunk in stream) {
      buffer += chunk;
      yield buffer;
    }
  } finally {
    AiDio.instance.cancel();
    await AiCache.setAiCache(hash, buffer, identifier);
  }
}

/// A stream generator for AI responses without relying on WidgetRef.
Stream<String> aiGenerateStreamWithoutRef(
  List<AiMessage> messages, {
  String? identifier,
  Map<String, String>? config,
  bool regenerate = false,
}) async* {
  identifier ??= Prefs().selectedAiService;
  config ??= Prefs().getAiConfig(identifier);
  String buffer = '';

  final url = config['url'];
  if (url == null || url.isEmpty) {
    yield L10n.of(navigatorKey.currentContext!).aiServiceNotConfigured;
    return;
  }

  AnxLog.info('aiGenerateStreamWithoutRef: $identifier');

  final messagesStr =
      messages.map((m) => '${m.role.toJson()}: ${m.content}').join('\n');
  final hash = messagesStr.hashCode;
  final aiCache = await AiCache.getAiCache(hash);

  if (aiCache != null && aiCache.isNotEmpty && !regenerate) {
    AnxLog.info('aiGenerateStreamWithoutRef: Cache hit hash: $hash');
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

  try {
    Stream<String> stream =
        AiFactory.generateStream(identifier, formattedMessages, config);

    await for (final chunk in stream) {
      buffer += chunk;
      yield buffer;
    }
  } catch (e) {
    AnxLog.severe('AI translation error: $e');
    yield L10n.of(navigatorKey.currentContext!).translateError + e.toString();
  } finally {
    AiDio.instance.cancel();
    await AiCache.setAiCache(hash, buffer, identifier);
  }
}
