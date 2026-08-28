import 'dart:convert';

import 'package:anx_reader/models/reading_memory.dart';
import 'package:crypto/crypto.dart';

class ReadingMemoryAiService {
  List<ReadingMemoryTopic> parseTopics(String response,
      {required int bookId,
      required String batchId,
      required Set<String> allowedSourceIds,
      required int now}) {
    final decoded = _decodeList(response);
    if (decoded.length < 2 || decoded.length > 8) {
      throw const FormatException('Expected 2-8 topics');
    }
    final titles = <String>{};
    return decoded.map((raw) {
      final item = _object(raw);
      final title = _text(item['title']);
      final normalized = title.toLowerCase();
      if (!titles.add(normalized)) {
        throw const FormatException('Duplicate topic');
      }
      final sources = _ids(item['sourceIds'], allowedSourceIds);
      return ReadingMemoryTopic(
          id: 'topic-$batchId-${titles.length}',
          bookId: bookId,
          title: title,
          summary: _text(item['summary']),
          status: ReadingMemoryItemStatus.suggested,
          batchId: batchId,
          sourceIds: sources,
          createdAt: now,
          updatedAt: now);
    }).toList(growable: false);
  }

  List<ReadingKnowledgeCard> parseCards(String response,
      {required int bookId,
      required ReadingMemoryTopic topic,
      required Set<String> allowedSourceIds,
      required int now}) {
    final decoded = _decodeList(response);
    if (decoded.length < 3 || decoded.length > 8) {
      throw const FormatException('Expected 3-8 cards');
    }
    final questions = <String>{};
    return decoded.map((raw) {
      final item = _object(raw);
      final question = _text(item['question']);
      final normalized = question.toLowerCase().replaceAll(RegExp(r'\s+'), '');
      if (!questions.add(normalized)) {
        throw const FormatException('Duplicate card');
      }
      final sources = _ids(item['sourceIds'], allowedSourceIds);
      final signature = sha256
          .convert(
              utf8.encode('$normalized|${([...sources]..sort()).join('|')}'))
          .toString();
      return ReadingKnowledgeCard(
          id: 'card-$bookId-$signature',
          bookId: bookId,
          topicId: topic.id,
          question: question,
          answer: _text(item['answer']),
          status: ReadingMemoryItemStatus.suggested,
          sourceIds: sources,
          nextReviewAt: now,
          createdAt: now,
          updatedAt: now);
    }).toList(growable: false);
  }

  String topicPrompt(List<ReadingMemorySource> sources) =>
      '''将当前书的难点和划线整理成 2-8 个可确认主题。
只输出 JSON 数组，不要 Markdown。每项格式：{"title":"短标题","summary":"一句摘要","sourceIds":["输入中的来源ID"]}。
不得使用输入之外的来源 ID，不得重复主题。来源：${jsonEncode(sources.map((s) => {
            'id': s.id,
            'chapter': s.chapterTitle,
            'text': s.text
          }).toList())}''';

  String cardPrompt(
          ReadingMemoryTopic topic, List<ReadingMemorySource> sources) =>
      '''根据已确认主题生成 3-8 张知识卡。
只输出 JSON 数组，不要 Markdown。每项格式：{"question":"无需上下文也能理解的问题","answer":"简短准确答案","sourceIds":["输入中的来源ID"]}。
不得使用输入之外的来源 ID，不得重复问题，不得编造来源。
主题：${topic.title}；摘要：${topic.summary}
来源：${jsonEncode(sources.map((s) => {
            'id': s.id,
            'chapter': s.chapterTitle,
            'text': s.text
          }).toList())}''';

  List<dynamic> _decodeList(String response) {
    final cleaned = response
        .replaceFirst(RegExp(r'^\s*```(?:json)?', caseSensitive: false), '')
        .replaceFirst(RegExp(r'```\s*$'), '')
        .trim();
    final value = jsonDecode(cleaned);
    if (value is! List) throw const FormatException('Expected array');
    return value;
  }

  Map<String, dynamic> _object(Object? value) {
    if (value is! Map) throw const FormatException('Expected object');
    return Map<String, dynamic>.from(value);
  }

  String _text(Object? value) {
    final text = value?.toString().trim() ?? '';
    if (text.isEmpty) throw const FormatException('Empty text');
    return text;
  }

  List<String> _ids(Object? value, Set<String> allowed) {
    if (value is! List || value.isEmpty) {
      throw const FormatException('Missing sources');
    }
    final ids = value.map((v) => v.toString()).toSet();
    if (!allowed.containsAll(ids)) {
      throw const FormatException('Unknown source');
    }
    return ids.toList(growable: false);
  }
}
