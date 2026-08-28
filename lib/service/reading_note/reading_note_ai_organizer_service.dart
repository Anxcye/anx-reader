import 'dart:convert';

import 'package:anx_reader/models/reading_note_ai.dart';

class ReadingNoteAiInput {
  const ReadingNoteAiInput({
    required this.sourceId,
    required this.sourceType,
    required this.sourceRef,
    required this.title,
    required this.quote,
    required this.body,
    required this.tags,
    required this.chapter,
    required this.contentHash,
  });

  final String sourceId;
  final ReadingNoteAiSourceType sourceType;
  final String sourceRef;
  final String title;
  final String quote;
  final String body;
  final List<String> tags;
  final String chapter;
  final String contentHash;

  Map<String, dynamic> toPromptJson() => {
        'sourceId': sourceId,
        'title': title,
        'quote': quote,
        'body': body,
        'tags': tags,
        'chapter': chapter,
      };
}

class ReadingNoteAiParsedSuggestion {
  const ReadingNoteAiParsedSuggestion({
    required this.sourceId,
    required this.title,
    required this.body,
    required this.tags,
    required this.existingTopicIds,
    required this.newTopics,
  });
  final String sourceId;
  final String title;
  final String body;
  final List<String> tags;
  final List<String> existingTopicIds;
  final List<Map<String, dynamic>> newTopics;
}

class ReadingNoteAiOrganizerService {
  String prompt({
    required String bookTitle,
    required String author,
    required List<ReadingNoteAiInput> inputs,
    required List<Map<String, String>> keptTopics,
  }) =>
      '''整理当前书的阅读笔记，只输出 JSON 数组，不要 Markdown。
每项格式：{"sourceId":"输入ID","title":"建议标题或空字符串","body":"简洁整理稿或空字符串","tags":["标签"],"existingTopicIds":["已有主题ID"],"newTopics":[{"title":"新主题","summary":"一句摘要"}]}。
不得修改原文，不得使用输入外的 sourceId 或主题 ID。新主题总数最多 8 个。
书名：$bookTitle；作者：$author
已有主题：${jsonEncode(keptTopics)}
笔记：${jsonEncode(inputs.map((item) => item.toPromptJson()).toList())}''';

  List<ReadingNoteAiParsedSuggestion> parse(
    String response, {
    required Set<String> allowedSourceIds,
    required Set<String> allowedTopicIds,
  }) {
    final cleaned = response
        .replaceFirst(RegExp(r'^\s*```(?:json)?', caseSensitive: false), '')
        .replaceFirst(RegExp(r'```\s*$'), '')
        .trim();
    final decoded = jsonDecode(cleaned);
    if (decoded is! List || decoded.isEmpty || decoded.length > 30) {
      throw const FormatException('Expected 1-30 suggestions');
    }
    final seenSources = <String>{};
    final newTopicTitles = <String>{};
    var newTopicCount = 0;
    return decoded.map((raw) {
      if (raw is! Map) throw const FormatException('Expected object');
      final item = Map<String, dynamic>.from(raw);
      final sourceId = _text(item['sourceId']);
      if (!allowedSourceIds.contains(sourceId) || !seenSources.add(sourceId)) {
        throw const FormatException('Unknown or duplicate source');
      }
      final topicIds = _strings(item['existingTopicIds']).toSet();
      if (!allowedTopicIds.containsAll(topicIds)) {
        throw const FormatException('Unknown topic');
      }
      final newTopics = <Map<String, dynamic>>[];
      for (final rawTopic in item['newTopics'] as List? ?? const []) {
        if (rawTopic is! Map) throw const FormatException('Invalid topic');
        final topic = Map<String, dynamic>.from(rawTopic);
        final title = _text(topic['title']);
        final summary = _text(topic['summary']);
        final normalized = title.toLowerCase().replaceAll(RegExp(r'\s+'), '');
        if (!newTopicTitles.add(normalized)) continue;
        newTopicCount++;
        if (newTopicCount > 8) {
          throw const FormatException('Too many new topics');
        }
        newTopics.add({'title': title, 'summary': summary});
      }
      final title = item['title']?.toString().trim() ?? '';
      final body = item['body']?.toString().trim() ?? '';
      final tags = _strings(item['tags'])
          .map((tag) => tag.trim())
          .where((tag) => tag.isNotEmpty)
          .toSet()
          .take(8)
          .toList();
      if (title.isEmpty &&
          body.isEmpty &&
          tags.isEmpty &&
          topicIds.isEmpty &&
          newTopics.isEmpty) {
        throw const FormatException('Empty suggestion');
      }
      return ReadingNoteAiParsedSuggestion(
        sourceId: sourceId,
        title: title,
        body: body,
        tags: tags,
        existingTopicIds: topicIds.toList(),
        newTopics: newTopics,
      );
    }).toList(growable: false);
  }

  String correctionPrompt(String originalPrompt, String invalidResponse) =>
      '''返回未通过校验。请只输出合法 JSON 数组，不要解释。sourceId 和 existingTopicIds 必须来自原始任务，新主题总数不超过 8。
原始任务：$originalPrompt
待纠正返回：$invalidResponse''';

  String _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) throw const FormatException('Empty text');
    return text;
  }

  List<String> _strings(Object? value) {
    if (value == null) return const [];
    if (value is! List) throw const FormatException('Expected list');
    return value.map((item) => item.toString()).toList(growable: false);
  }
}
