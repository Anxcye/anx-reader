import 'dart:convert';

import 'package:anx_reader/models/reading_memory.dart';
import 'package:anx_reader/service/ai/reading_memory_ai_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = ReadingMemoryAiService();
  test('topic parser rejects unknown sources and duplicate titles', () {
    String topics(List<Map<String, Object>> values) => jsonEncode(values);
    expect(
        () => service.parseTopics(
            topics([
              {
                'title': 'A',
                'summary': 'a',
                'sourceIds': ['s1']
              },
              {
                'title': 'B',
                'summary': 'b',
                'sourceIds': ['unknown']
              },
            ]),
            bookId: 1,
            batchId: 'b',
            allowedSourceIds: {'s1'},
            now: 1),
        throwsFormatException);
    expect(
        () => service.parseTopics(
            topics([
              {
                'title': 'A',
                'summary': 'a',
                'sourceIds': ['s1']
              },
              {
                'title': 'a',
                'summary': 'b',
                'sourceIds': ['s1']
              },
            ]),
            bookId: 1,
            batchId: 'b',
            allowedSourceIds: {'s1'},
            now: 1),
        throwsFormatException);
  });

  test('card IDs are stable across source order and reject empty answers', () {
    const topic = ReadingMemoryTopic(
        id: 't',
        bookId: 1,
        title: 'T',
        summary: 'S',
        status: ReadingMemoryItemStatus.kept,
        batchId: 'b',
        sourceIds: ['s1', 's2'],
        createdAt: 1,
        updatedAt: 1);
    List<ReadingKnowledgeCard> parse(List<String> ids) => service.parseCards(
        jsonEncode([
          {'question': 'Q1', 'answer': 'A1', 'sourceIds': ids},
          {
            'question': 'Q2',
            'answer': 'A2',
            'sourceIds': ['s1']
          },
          {
            'question': 'Q3',
            'answer': 'A3',
            'sourceIds': ['s2']
          },
        ]),
        bookId: 1,
        topic: topic,
        allowedSourceIds: {'s1', 's2'},
        now: 1);
    expect(parse(['s1', 's2']).first.id, parse(['s2', 's1']).first.id);
    final anotherTopic = ReadingMemoryTopic(
        id: 'another-topic',
        bookId: topic.bookId,
        title: topic.title,
        summary: topic.summary,
        status: topic.status,
        batchId: 'another-batch',
        sourceIds: topic.sourceIds,
        createdAt: 2,
        updatedAt: 2);
    final sameCardFromAnotherBatch = service
        .parseCards(
            jsonEncode([
              {
                'question': 'Q1',
                'answer': 'A1',
                'sourceIds': ['s2', 's1']
              },
              {
                'question': 'Q2',
                'answer': 'A2',
                'sourceIds': ['s1']
              },
              {
                'question': 'Q3',
                'answer': 'A3',
                'sourceIds': ['s2']
              },
            ]),
            bookId: 1,
            topic: anotherTopic,
            allowedSourceIds: {'s1', 's2'},
            now: 2)
        .first;
    expect(parse(['s1', 's2']).first.id, sameCardFromAnotherBatch.id);
    expect(
        () => service.parseCards(
            jsonEncode([
              {
                'question': 'Q1',
                'answer': '',
                'sourceIds': ['s1']
              },
              {
                'question': 'Q2',
                'answer': 'A2',
                'sourceIds': ['s1']
              },
              {
                'question': 'Q3',
                'answer': 'A3',
                'sourceIds': ['s1']
              },
            ]),
            bookId: 1,
            topic: topic,
            allowedSourceIds: {'s1'},
            now: 1),
        throwsFormatException);
  });
}
