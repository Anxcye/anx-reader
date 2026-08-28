import 'package:anx_reader/config/shared_preference_provider.dart';
import 'package:anx_reader/l10n/generated/L10n.dart';
import 'package:anx_reader/enums/lang_list.dart';
import 'package:anx_reader/models/ai_provider.dart';
import 'package:anx_reader/service/ai/prompt_generate.dart';
import 'package:anx_reader/service/ai/index.dart';
import 'package:anx_reader/service/ai/ai_context_assembler.dart';
import 'package:anx_reader/service/config/config_item.dart';
import 'package:anx_reader/service/translate/index.dart';
import 'package:anx_reader/service/translate/translation_ai_provider_resolver.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:anx_reader/widgets/ai/ai_stream.dart';
import 'package:flutter/material.dart';
import 'package:langchain_core/chat_models.dart';

typedef AiTranslationStreamGenerator = Stream<String>
    Function(List<ChatMessage> messages, {String? identifier});

typedef AiTranslationTextGenerator = Future<String> Function(
  List<ChatMessage> messages, {
  String? identifier,
  bool allowFallback,
});

typedef AiTranslationWidgetBuilder = Widget
    Function(PromptTemplatePayload prompt, {String? identifier});

class AiTranslateProvider extends TranslateServiceProvider {
  AiTranslateProvider({
    AiTranslationStreamGenerator? streamGenerator,
    AiTranslationTextGenerator? textGenerator,
    AiTranslationWidgetBuilder? streamWidgetBuilder,
  })  : _streamGenerator = streamGenerator ?? _defaultStreamGenerator,
        _textGenerator = textGenerator ?? _defaultTextGenerator,
        _streamWidgetBuilder =
            streamWidgetBuilder ?? _defaultStreamWidgetBuilder;

  final AiTranslationStreamGenerator _streamGenerator;
  final AiTranslationTextGenerator _textGenerator;
  final AiTranslationWidgetBuilder _streamWidgetBuilder;

  @override
  TranslateService get service => TranslateService.ai;

  @override
  String getLabel(BuildContext context) => L10n.of(context).navBarAI;

  /// AI translation uses native language names (e.g., "简体中文", "English")
  /// instead of ISO codes for better prompt understanding.
  @override
  String mapLanguageCode(LangListEnum lang) => lang.nativeName;

  @override
  Widget translate(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  }) {
    final prompt = isFullText
        ? generatePromptFullTextTranslate(
            text,
            mapLanguageCode(to),
            mapLanguageCode(from),
          )
        : generatePromptTranslate(
            text,
            mapLanguageCode(to),
            mapLanguageCode(from),
            contextText: contextText,
          );

    return _streamWidgetBuilder(
      prompt,
      identifier: _resolvePrimaryTranslationProviderId(),
    );
  }

  @override
  Stream<String> translateStream(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  }) async* {
    try {
      final payload = isFullText
          ? generatePromptFullTextTranslate(
              text,
              mapLanguageCode(to),
              mapLanguageCode(from),
            )
          : generatePromptTranslate(
              text,
              mapLanguageCode(to),
              mapLanguageCode(from),
              contextText: contextText,
            );

      final messages = payload.buildMessages();

      await for (final result in _streamGenerator(
        messages,
        identifier: _resolvePrimaryTranslationProviderId(),
      )) {
        yield result;
      }
    } catch (e) {
      yield* Stream<String>.error(e);
    }
  }

  @override
  Future<String> translateTextOnly(
    String text,
    LangListEnum from,
    LangListEnum to, {
    String? contextText,
    bool isFullText = false,
  }) async {
    final payload = isFullText
        ? generatePromptFullTextTranslate(
            text,
            mapLanguageCode(to),
            mapLanguageCode(from),
          )
        : generatePromptTranslate(
            text,
            mapLanguageCode(to),
            mapLanguageCode(from),
            contextText: contextText,
          );
    final messages = payload.buildMessages();
    final primaryId = _resolvePrimaryTranslationProviderId();

    try {
      final result = await _generateValidAiTranslation(
        messages,
        identifier: primaryId,
        allowFallback: false,
      );
      return result;
    } catch (e) {
      final fallbackId = await resolveRunnableAiFallbackProviderId(
        primaryIdentifier: primaryId,
      );
      if (fallbackId == null) rethrow;

      AnxLog.info('Trying AI translation fallback provider: $fallbackId');
      final fallbackResult = await _generateValidAiTranslation(
        messages,
        identifier: fallbackId,
        allowFallback: false,
      );
      AnxLog.info(
        'AI translation fallback succeeded: $primaryId -> $fallbackId',
      );
      return fallbackResult;
    }
  }

  Future<String> _generateValidAiTranslation(
    List<ChatMessage> messages, {
    String? identifier,
    bool allowFallback = true,
  }) async {
    final result = await _textGenerator(
      messages,
      identifier: identifier,
      allowFallback: allowFallback,
    );

    if (result.trim().isNotEmpty &&
        result != '...' &&
        !isFailedTranslationResult(result)) {
      return result;
    }

    throw Exception('AI translation returned no valid result: $result');
  }

  String? resolvePrimaryTranslationProviderIdForTest() {
    return _resolvePrimaryTranslationProviderId();
  }

  String? _resolvePrimaryTranslationProviderId() {
    final providers = _loadStoredAiProviders();
    final resolution = TranslationAiProviderResolver.resolve(
      providers: providers,
      selectedProviderId: Prefs().selectedAiService,
      translationProviderId: Prefs().translationAiProvider,
    );

    if (resolution.invalidDedicatedProviderId != null) {
      Prefs().translationAiProvider = null;
    }

    return resolution.effectiveProviderId;
  }

  List<AiProvider> _loadStoredAiProviders() {
    try {
      return Prefs()
          .getAiProviders()
          .map((json) => AiProvider.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  @override
  List<ConfigItem> getConfigItems(BuildContext context) {
    return [
      ConfigItem(
        key: 'tip',
        label: 'Tip',
        type: ConfigItemType.tip,
        defaultValue: L10n.of(context).settingsTranslateAiTip,
      ),
    ];
  }
}

Stream<String> _defaultStreamGenerator(
  List<ChatMessage> messages, {
  String? identifier,
}) {
  return aiGenerateStream(
    messages,
    identifier: identifier,
    regenerate: false,
    task: AiContextTask.translation,
  );
}

Future<String> _defaultTextGenerator(
  List<ChatMessage> messages, {
  String? identifier,
  bool allowFallback = true,
}) {
  return aiGenerateText(
    messages,
    identifier: identifier,
    regenerate: false,
    allowFallback: allowFallback,
    task: AiContextTask.translation,
  );
}

Widget _defaultStreamWidgetBuilder(
  PromptTemplatePayload prompt, {
  String? identifier,
}) {
  return AiStream(prompt: prompt, identifier: identifier, regenerate: true);
}
