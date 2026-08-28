import 'dart:convert';
import 'dart:io';

import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/fiction_backfill_service.dart';
import 'package:archive/archive.dart';
import 'package:langchain_anthropic/langchain_anthropic.dart';
import 'package:langchain_core/chat_models.dart';
import 'package:langchain_core/prompts.dart';

/// Manual, opt-in Story Atlas benchmark for a real EPUB.
///
/// Credentials are read only from environment variables and are never logged:
///
/// ANX_BENCHMARK_API_KEY=... \
/// ANX_BENCHMARK_BASE_URL=https://... \
/// ANX_BENCHMARK_MODEL=... \
/// dart run tool/fiction_story_atlas_benchmark.dart book.epub report.json
Future<void> main(List<String> arguments) async {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/fiction_story_atlas_benchmark.dart '
      '<epub> <report.json>',
    );
    exitCode = 64;
    return;
  }
  final localCompletionsUrl =
      Platform.environment['ANX_BENCHMARK_LOCAL_COMPLETIONS_URL']?.trim() ?? '';
  final localChatUrl =
      Platform.environment['ANX_BENCHMARK_LOCAL_CHAT_URL']?.trim() ?? '';
  final apiKey = Platform.environment['ANX_BENCHMARK_API_KEY']?.trim() ?? '';
  final baseUrl = Platform.environment['ANX_BENCHMARK_BASE_URL']?.trim() ?? '';
  final modelName = Platform.environment['ANX_BENCHMARK_MODEL']?.trim() ?? '';
  if (modelName.isEmpty ||
      (localCompletionsUrl.isEmpty &&
          localChatUrl.isEmpty &&
          (apiKey.isEmpty || baseUrl.isEmpty))) {
    stderr.writeln(
      'ANX_BENCHMARK_MODEL and either ANX_BENCHMARK_LOCAL_CHAT_URL, '
      'ANX_BENCHMARK_LOCAL_COMPLETIONS_URL '
      'or both ANX_BENCHMARK_API_KEY and ANX_BENCHMARK_BASE_URL are required.',
    );
    exitCode = 64;
    return;
  }
  final maxOutputTokens = int.tryParse(
        Platform.environment['ANX_BENCHMARK_MAX_OUTPUT_TOKENS'] ?? '',
      ) ??
      1024;
  final maxChapters = int.tryParse(
        Platform.environment['ANX_BENCHMARK_MAX_CHAPTERS'] ?? '',
      ) ??
      100;
  final batchSize = int.tryParse(
        Platform.environment['ANX_BENCHMARK_BATCH_SIZE'] ?? '',
      ) ??
      6;
  final maxInputCharacters = int.tryParse(
        Platform.environment['ANX_BENCHMARK_MAX_INPUT_CHARACTERS'] ?? '',
      ) ??
      24000;
  final localRelationshipOnly =
      Platform.environment['ANX_BENCHMARK_LOCAL_RELATIONSHIP_ONLY'] == '1';
  final localCharacterEvidenceOnly =
      Platform.environment['ANX_BENCHMARK_LOCAL_CHARACTER_EVIDENCE_ONLY'] ==
          '1';
  final localChunkCharacters = int.tryParse(
        Platform.environment['ANX_BENCHMARK_LOCAL_CHUNK_CHARACTERS'] ?? '',
      ) ??
      0;
  final concurrency = int.tryParse(
        Platform.environment['ANX_BENCHMARK_CONCURRENCY'] ?? '',
      ) ??
      1;
  final epub = File(arguments[0]);
  final output = File(arguments[1]);
  final archive = ZipDecoder().decodeBytes(await epub.readAsBytes());
  final entries = <String, String>{};
  for (final file in archive.files.where((entry) => entry.isFile)) {
    if (!file.name.toLowerCase().endsWith('.html') &&
        !file.name.toLowerCase().endsWith('.xhtml')) {
      continue;
    }
    entries[file.name] = utf8.decode(file.content as List<int>);
  }

  final numbered = <({int number, String href, String title, String text})>[];
  for (final entry in entries.entries) {
    final title = _firstMatch(
      entry.value,
      RegExp(r'<h[1-6][^>]*>(.*?)</h[1-6]>',
          caseSensitive: false, dotAll: true),
    );
    final match = RegExp(r'^\s*第(\d+)章\s*(.*)$').firstMatch(title);
    if (match == null) continue;
    numbered.add((
      number: int.parse(match.group(1)!),
      href: entry.key.replaceFirst(RegExp(r'^OEBPS/'), ''),
      title: _decodeEntities(title),
      text: _htmlText(entry.value),
    ));
  }
  numbered.sort((left, right) => left.number.compareTo(right.number));
  final selected = numbered.take(maxChapters).toList(growable: false);
  if (selected.length != maxChapters) {
    throw StateError(
      'Expected $maxChapters numbered chapters, found ${selected.length}.',
    );
  }

  final model = localCompletionsUrl.isEmpty && localChatUrl.isEmpty
      ? ChatAnthropic(
          apiKey: apiKey,
          baseUrl: baseUrl,
          defaultOptions: ChatAnthropicOptions(
            model: modelName,
            temperature: 0,
            maxTokens: maxOutputTokens,
          ),
        )
      : null;
  final rawResponses = <Map<String, Object?>>[];
  var requestCount = 0;
  var inputTokens = 0;
  var outputTokens = 0;
  final startedAt = DateTime.now();
  final prepared = <({int number, String href, String title, String text})>[
    for (final chapter in selected)
      if (localChunkCharacters > 0)
        ..._splitChapter(chapter, localChunkCharacters)
      else
        chapter,
  ];
  try {
    final artifacts = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: 1,
      chapters: [
        for (var index = 0; index < prepared.length; index++)
          FictionBackfillChapter(
            href: prepared[index].href,
            title: prepared[index].title,
            startProgress: index / prepared.length,
            endProgress: (index + 1) / prepared.length,
          ),
      ],
      loadChapter: (href) async =>
          prepared.firstWhere((chapter) => chapter.href == href).text,
      generate: (prompt) async {
        final requestId = ++requestCount;
        stdout.writeln('Request $requestId started');
        if (localCompletionsUrl.isNotEmpty || localChatUrl.isNotEmpty) {
          final localPrompt = localCharacterEvidenceOnly
              ? _localCharacterEvidencePrompt(prompt)
              : localRelationshipOnly
                  ? _localRelationshipPrompt(prompt)
                  : prompt;
          final response = localChatUrl.isNotEmpty
              ? await _localChat(
                  url: localChatUrl,
                  model: modelName,
                  prompt: localPrompt,
                  maxTokens: maxOutputTokens,
                )
              : await _localCompletion(
                  url: localCompletionsUrl,
                  model: modelName,
                  prompt: localPrompt,
                  maxTokens: maxOutputTokens,
                );
          inputTokens += response.promptTokens;
          outputTokens += response.responseTokens;
          rawResponses.add({
            'request': requestId,
            'finishReason': response.finishReason,
            'promptTokens': response.promptTokens,
            'responseTokens': response.responseTokens,
            'content': response.content,
          });
          stdout.writeln(
            'Request $requestId finished: ${response.promptTokens} in, '
            '${response.responseTokens} out, ${response.finishReason}',
          );
          return response.content;
        }
        final result = await model!.invoke(
          PromptValue.chat([ChatMessage.humanText(prompt)]),
        );
        final usage = result.usage;
        inputTokens += usage.promptTokens ?? 0;
        outputTokens += usage.responseTokens ?? 0;
        final content = result.output.content;
        rawResponses.add({
          'request': requestId,
          'finishReason': result.finishReason.name,
          'promptTokens': usage.promptTokens,
          'responseTokens': usage.responseTokens,
          'content': content,
        });
        stdout.writeln(
          'Request $requestId finished: ${usage.promptTokens ?? 0} in, '
          '${usage.responseTokens ?? 0} out, ${result.finishReason.name}',
        );
        return content;
      },
      sessionId: 'benchmark',
      ingestedAt: startedAt.millisecondsSinceEpoch,
      batchSize: batchSize,
      maxInputCharacters: maxInputCharacters,
      concurrency: concurrency,
    );
    final report = _report(
      epub: epub,
      selected: selected,
      artifacts: artifacts,
      requestCount: requestCount,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      maxOutputTokens: maxOutputTokens,
      batchSize: batchSize,
      maxInputCharacters: maxInputCharacters,
      concurrency: concurrency,
      startedAt: startedAt,
      rawResponses: rawResponses,
      error: null,
    );
    await output
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    stdout.writeln('Report: ${output.path}');
  } catch (error, stackTrace) {
    final report = _report(
      epub: epub,
      selected: selected,
      artifacts: const [],
      requestCount: requestCount,
      inputTokens: inputTokens,
      outputTokens: outputTokens,
      maxOutputTokens: maxOutputTokens,
      batchSize: batchSize,
      maxInputCharacters: maxInputCharacters,
      concurrency: concurrency,
      startedAt: startedAt,
      rawResponses: rawResponses,
      error: '$error\n$stackTrace',
    );
    await output
        .writeAsString(const JsonEncoder.withIndent('  ').convert(report));
    stderr.writeln('Benchmark failed after $requestCount requests: $error');
    stderr.writeln('Partial report: ${output.path}');
    exitCode = 1;
  } finally {
    model?.close();
  }
}

Future<
    ({
      String content,
      String finishReason,
      int promptTokens,
      int responseTokens,
    })> _localChat({
  required String url,
  required String model,
  required String prompt,
  required int maxTokens,
}) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'model': model,
      'messages': [
        {'role': 'system', 'content': '只依据正文抽取，只返回严格 JSON。'},
        {'role': 'user', 'content': prompt},
      ],
      'temperature': 0,
      'max_tokens': maxTokens,
    }));
    final response = await request.close().timeout(const Duration(minutes: 4));
    final raw = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Local chat failed with HTTP ${response.statusCode}: $raw',
        uri: Uri.parse(url),
      );
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final choices = decoded['choices'] as List? ?? const [];
    final choice = choices.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(choices.first as Map);
    final message = Map<String, dynamic>.from(
      choice['message'] as Map? ?? const <String, dynamic>{},
    );
    final usage = Map<String, dynamic>.from(
      decoded['usage'] as Map? ?? const <String, dynamic>{},
    );
    return (
      content: message['content']?.toString() ?? '',
      finishReason: choice['finish_reason']?.toString() ?? 'unknown',
      promptTokens: (usage['prompt_tokens'] as num?)?.toInt() ?? 0,
      responseTokens: (usage['completion_tokens'] as num?)?.toInt() ?? 0,
    );
  } finally {
    client.close(force: true);
  }
}

List<({int number, String href, String title, String text})> _splitChapter(
  ({int number, String href, String title, String text}) chapter,
  int maxCharacters,
) {
  final result = <({int number, String href, String title, String text})>[];
  var start = 0;
  var part = 1;
  while (start < chapter.text.length) {
    var end = (start + maxCharacters).clamp(0, chapter.text.length);
    if (end < chapter.text.length) {
      final paragraph = chapter.text.lastIndexOf('\n', end);
      if (paragraph > start + maxCharacters ~/ 2) end = paragraph;
    }
    result.add((
      number: chapter.number,
      href: '${chapter.href}.local-part-$part',
      title: '${chapter.title}（片段 $part）',
      text: chapter.text.substring(start, end),
    ));
    start = end;
    part++;
  }
  return result;
}

String _localRelationshipPrompt(String source) {
  final chapterStart = source.indexOf('章节 href：');
  if (chapterStart < 0) return source;
  final known = RegExp(r'已建档人物[^：]*：([^\n]+)').firstMatch(source)?.group(1);
  return '''
任务：从小说正文提取实际登场人物和正文明确的人物关系，只返回紧凑 JSON，不解释。
格式：[{"chapterHref":"原 href","items":[{"kind":"character","payload":{"name":"完整姓名"}},{"kind":"relationship","payload":{"from":"完整姓名","to":"完整姓名","relation":"简短中文关系"}}]}]
规则：
1. from 对 to 的 relation 方向必须正确；“甲是乙祖父”输出 from=甲,to=乙,relation=祖孙。
2. 只收录本章实际登场者；历史典故、类比人物、泛称不收录。
3. 第五、第八、第一等数字姓必须保留完整；不得自行推成同宗或兄弟，但正文明确写出时按原文保留。
4. 每个人物只输出一次；只写完整姓名，不写摘要、事件、单字简称或自造 ID。
${known == null ? '' : '已建档人物，不再输出 character：$known\n'}
${source.substring(chapterStart)}

JSON 后输出 <END>：
''';
}

String _localCharacterEvidencePrompt(String source) {
  final chapterStart = source.indexOf('章节 href：');
  if (chapterStart < 0) return source;
  final known = RegExp(r'已建档人物[^：]*：([^\n]+)').firstMatch(source)?.group(1);
  return '''
任务：从小说正文中抽取本章实际登场、有自己言行或被明确指代的具名人物。只返回紧凑 JSON，不解释。
格式：[{"chapterHref":"原 href","items":[{"kind":"character","payload":{"name":"完整规范姓名","aliases":[],"courtesyNames":[],"artNames":[],"evidence":"正文中包含该人物名或明确指代的连续原文，最多40字"}}]}]
规则：
1. evidence 必须从所给正文逐字复制，不得改写、总结或补全。
2. 只收录具有稳定专名的人物；县宰、诸生、少年、士卒、百姓等角色或群体不收录。
3. 历史典故、类比、转述中只被提到而未参与本章场景的人物不收录。
4. 第五、第八、第一等数字姓必须保留完整。中文姓名、字、号分字段；不把同一人的名、字、号拆成多人。
5. 不输出 relationship、event、scene、mystery 或 clue。不推断人际关系。
6. 每个人物只输出一次；没有符合项时 items 返回空数组。
${known == null ? '' : '已建档人物，不再输出：$known\n'}
${source.substring(chapterStart)}

JSON 后输出 <END>：
''';
}

Future<
    ({
      String content,
      String finishReason,
      int promptTokens,
      int responseTokens,
    })> _localCompletion({
  required String url,
  required String model,
  required String prompt,
  required int maxTokens,
}) async {
  final client = HttpClient();
  try {
    final request = await client.postUrl(Uri.parse(url));
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode({
      'model': model,
      'prompt': prompt,
      'temperature': 0,
      'max_tokens': maxTokens,
      'stop': ['<END>'],
    }));
    final response = await request.close().timeout(const Duration(minutes: 4));
    final raw = await utf8.decoder.bind(response).join();
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw HttpException(
        'Local completion failed with HTTP ${response.statusCode}: $raw',
        uri: Uri.parse(url),
      );
    }
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    final choices = decoded['choices'] as List? ?? const [];
    final choice = choices.isEmpty
        ? const <String, dynamic>{}
        : Map<String, dynamic>.from(choices.first as Map);
    final usage = Map<String, dynamic>.from(
      decoded['usage'] as Map? ?? const <String, dynamic>{},
    );
    return (
      content: choice['text']?.toString() ?? '',
      finishReason: choice['finish_reason']?.toString() ?? 'unknown',
      promptTokens: (usage['prompt_tokens'] as num?)?.toInt() ?? 0,
      responseTokens: (usage['completion_tokens'] as num?)?.toInt() ?? 0,
    );
  } finally {
    client.close(force: true);
  }
}

Map<String, Object?> _report({
  required File epub,
  required List<({int number, String href, String title, String text})>
      selected,
  required List<ReadingArtifact> artifacts,
  required int requestCount,
  required int inputTokens,
  required int outputTokens,
  required int maxOutputTokens,
  required int batchSize,
  required int maxInputCharacters,
  required int concurrency,
  required DateTime startedAt,
  required List<Map<String, Object?>> rawResponses,
  required String? error,
}) {
  final kindCounts = <String, int>{};
  for (final artifact in artifacts) {
    kindCounts.update(artifact.kind, (value) => value + 1, ifAbsent: () => 1);
  }
  final characters = artifacts
      .where((artifact) => artifact.kind == ReadingArtifactKinds.character)
      .toList(growable: false);
  final relationships = artifacts
      .where((artifact) => artifact.kind == ReadingArtifactKinds.relationship)
      .toList(growable: false);
  final names = characters
      .map((artifact) => artifact.payload['name']?.toString().trim() ?? '')
      .where((name) => name.isNotEmpty)
      .toList(growable: false);
  final normalizedNames = <String, int>{};
  for (final name in names) {
    normalizedNames.update(
      name.toLowerCase().replaceAll(RegExp(r'\s+'), ''),
      (count) => count + 1,
      ifAbsent: () => 1,
    );
  }
  String normalizeName(Object? value) =>
      value?.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), '') ??
      '';
  final relationshipEndpoints = <String>[];
  final unmatchedRelationshipEndpoints = <String>{};
  for (final relationship in relationships) {
    for (final field in const ['from', 'to']) {
      final endpoint = relationship.payload[field]?.toString().trim() ?? '';
      if (endpoint.isEmpty) continue;
      relationshipEndpoints.add(endpoint);
      if (!normalizedNames.containsKey(normalizeName(endpoint))) {
        unmatchedRelationshipEndpoints.add(endpoint);
      }
    }
  }
  final matchedEndpointCount = relationshipEndpoints.length -
      unmatchedRelationshipEndpoints.fold<int>(
        0,
        (count, endpoint) =>
            count +
            relationshipEndpoints.where((item) => item == endpoint).length,
      );
  final duplicateArtifactCount = names.length - normalizedNames.length;
  return {
    'epub': epub.path,
    'chapters': selected.length,
    'chapterRange': '${selected.first.title} — ${selected.last.title}',
    'elapsedSeconds': DateTime.now().difference(startedAt).inSeconds,
    'requestCount': requestCount,
    'maxOutputTokens': maxOutputTokens,
    'batchSize': batchSize,
    'maxInputCharacters': maxInputCharacters,
    'concurrency': concurrency,
    'inputTokens': inputTokens,
    'outputTokens': outputTokens,
    'artifactCounts': kindCounts,
    'extraction': {
      'characterArtifacts': characters.length,
      'relationshipArtifacts': relationships.length,
      'uniqueExactNames': normalizedNames.length,
      'duplicateCharacterArtifacts': duplicateArtifactCount,
      'duplicateCharacterRate':
          names.isEmpty ? 0 : duplicateArtifactCount / names.length,
      'repeatedExactNames': {
        for (final entry in normalizedNames.entries)
          if (entry.value > 1) entry.key: entry.value,
      },
      'characterNames': names,
      'relationshipEndpointCount': relationshipEndpoints.length,
      'matchedRelationshipEndpointCount': matchedEndpointCount,
      'relationshipEndpointMatchRate': relationshipEndpoints.isEmpty
          ? 1
          : matchedEndpointCount / relationshipEndpoints.length,
      'unmatchedRelationshipEndpoints': unmatchedRelationshipEndpoints.toList()
        ..sort(),
    },
    'responses': rawResponses,
    if (error != null) 'error': error,
  };
}

String _firstMatch(String html, RegExp expression) =>
    _decodeEntities(expression.firstMatch(html)?.group(1) ?? '')
        .replaceAll(RegExp(r'<[^>]+>'), '')
        .trim();

String _htmlText(String html) => _decodeEntities(html
        .replaceAll(
            RegExp(r'<(script|style)[^>]*>.*?</\1>',
                caseSensitive: false, dotAll: true),
            '')
        .replaceAll(RegExp(r'</(p|div|h[1-6]|li)>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<br\s*/?>', caseSensitive: false), '\n')
        .replaceAll(RegExp(r'<[^>]+>'), ' '))
    .replaceAll(RegExp(r'[ \t\u00a0]+'), ' ')
    .replaceAll(RegExp(r'\n\s*\n+'), '\n')
    .trim();

String _decodeEntities(String value) => value
    .replaceAll('&nbsp;', ' ')
    .replaceAll('&quot;', '"')
    .replaceAll('&apos;', "'")
    .replaceAll('&lt;', '<')
    .replaceAll('&gt;', '>')
    .replaceAll('&amp;', '&');
