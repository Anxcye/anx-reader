import 'dart:convert';

import 'package:anx_reader/service/reading_note/reading_note_ai_organizer_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final service = ReadingNoteAiOrganizerService();

  test('parses valid field-level suggestions', () {
    final parsed = service.parse(
      jsonEncode([
        {
          'sourceId': 'readingNote:n1',
          'title': '因果关系',
          'body': '作者先提出假设，再用案例验证。',
          'tags': ['方法', '方法'],
          'existingTopicIds': ['topic-1'],
          'newTopics': [
            {'title': '论证方法', 'summary': '梳理论证过程'}
          ],
        }
      ]),
      allowedSourceIds: {'readingNote:n1'},
      allowedTopicIds: {'topic-1'},
    );

    expect(parsed, hasLength(1));
    expect(parsed.single.tags, ['方法']);
    expect(parsed.single.existingTopicIds, ['topic-1']);
    expect(parsed.single.newTopics.single['title'], '论证方法');
  });

  test('rejects unknown and duplicate source ids', () {
    final unknown = jsonEncode([
      {
        'sourceId': 'readingNote:missing',
        'title': '标题',
        'body': '',
        'tags': [],
        'existingTopicIds': [],
        'newTopics': [],
      }
    ]);
    expect(
      () => service.parse(unknown,
          allowedSourceIds: {'readingNote:n1'}, allowedTopicIds: {}),
      throwsFormatException,
    );

    final duplicate = jsonEncode(List.generate(
        2,
        (_) => {
              'sourceId': 'readingNote:n1',
              'title': '标题',
              'body': '',
              'tags': [],
              'existingTopicIds': [],
              'newTopics': [],
            }));
    expect(
      () => service.parse(duplicate,
          allowedSourceIds: {'readingNote:n1'}, allowedTopicIds: {}),
      throwsFormatException,
    );
  });

  test('rejects unknown topics and more than eight new topics', () {
    final unknownTopic = jsonEncode([
      {
        'sourceId': 'readingNote:n1',
        'title': '',
        'body': '',
        'tags': [],
        'existingTopicIds': ['unknown'],
        'newTopics': [],
      }
    ]);
    expect(
      () => service.parse(unknownTopic,
          allowedSourceIds: {'readingNote:n1'}, allowedTopicIds: {}),
      throwsFormatException,
    );

    final excessive = jsonEncode([
      {
        'sourceId': 'readingNote:n1',
        'title': '标题',
        'body': '',
        'tags': [],
        'existingTopicIds': [],
        'newTopics':
            List.generate(9, (index) => {'title': '主题$index', 'summary': '摘要'}),
      }
    ]);
    expect(
      () => service.parse(excessive,
          allowedSourceIds: {'readingNote:n1'}, allowedTopicIds: {}),
      throwsFormatException,
    );
  });
}
