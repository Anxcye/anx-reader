// ignore_for_file: public_member_api_docs
import 'package:googleai_dart/googleai_dart.dart' as g;
import 'package:langchain_core/language_models.dart';
import 'package:langchain_core/llms.dart';

extension GenerateContentResponseMapper on g.GenerateContentResponse {
  LLMResult toLLMResult(final String id, final String model) {
    final candidate = candidates?.first;
    if (candidate == null) {
      throw StateError('No candidates in response');
    }

    // Extract text content from all text parts
    final output =
        candidate.content?.parts
            .whereType<g.TextPart>()
            .map((p) => p.text)
            .join('\n') ??
        '';

    return LLMResult(
      id: id,
      output: output,
      finishReason: _mapFinishReason(candidate.finishReason),
      metadata: {
        'model': model,
        'block_reason': promptFeedback?.blockReason?.name,
        'safety_ratings': candidate.safetyRatings
            ?.map(
              (r) => {
                'category': r.category.name,
                'probability': r.probability.name,
              },
            )
            .toList(growable: false),
        'citation_metadata': candidate.citationMetadata?.citationSources
            ?.map(
              (final g.CitationSource s) => {
                'start_index': s.startIndex,
                'end_index': s.endIndex,
                'uri': s.uri,
                'title': s.title,
                'license': s.license,
                'publication_date': s.publicationDate?.toIso8601String(),
              },
            )
            .toList(growable: false),
      },
      usage: LanguageModelUsage(
        promptTokens: usageMetadata?.promptTokenCount,
        responseTokens: usageMetadata?.candidatesTokenCount,
        totalTokens: usageMetadata?.totalTokenCount,
      ),
    );
  }

  FinishReason _mapFinishReason(final g.FinishReason? reason) =>
      switch (reason) {
        g.FinishReason.unspecified => FinishReason.unspecified,
        g.FinishReason.stop => FinishReason.stop,
        g.FinishReason.maxTokens => FinishReason.length,
        g.FinishReason.safety => FinishReason.contentFilter,
        g.FinishReason.recitation => FinishReason.recitation,
        g.FinishReason.other => FinishReason.unspecified,
        g.FinishReason.blocklist => FinishReason.contentFilter,
        g.FinishReason.prohibitedContent => FinishReason.contentFilter,
        g.FinishReason.spii => FinishReason.contentFilter,
        g.FinishReason.malformedFunctionCall => FinishReason.unspecified,
        null => FinishReason.unspecified,
      };
}
