import 'dart:convert';

import 'package:anx_reader/models/reading_agent.dart';
import 'package:anx_reader/service/ai/fiction_backfill_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('backfill never loads chapters beyond safe boundary', () async {
    final loaded = <String>[];
    final artifacts = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: .52,
      chapters: const [
        FictionBackfillChapter(
            href: 'early.xhtml',
            title: '前章',
            startProgress: .18,
            endProgress: .3),
        FictionBackfillChapter(
            href: 'partial.xhtml',
            title: '当前章',
            startProgress: .5,
            endProgress: .6),
        FictionBackfillChapter(
            href: 'future.xhtml',
            title: '后章',
            startProgress: .7,
            endProgress: .8),
      ],
      loadChapter: (href) async {
        loaded.add(href);
        return '林先生走进车站。';
      },
      generate: (_) async => jsonEncode([
        {
          'kind': 'character',
          'payload': {'name': '林先生', 'summary': '出现在车站'}
        }
      ]),
      sessionId: 'session',
      ingestedAt: 1234,
    );

    expect(loaded, ['early.xhtml']);
    expect(artifacts, hasLength(1));
    expect(artifacts.single.sourceProgress, .18);
    expect(artifacts.single.visibleFromProgress, .18);
    expect(artifacts.single.ingestedAt, 1234);
    expect(
        artifacts.single.ingestionMode, ReadingArtifactIngestionMode.backfill);
    expect(artifacts.single.isVisibleAtProgress(.1), isFalse);
    expect(artifacts.single.isVisibleAtProgress(.18), isTrue);
  });

  test('event output is validated and uses stable ids for deduplication',
      () async {
    Future<List<ReadingArtifact>> build({
      Iterable<ReadingArtifact> existing = const [],
    }) =>
        fictionBackfillService.build(
          bookId: 1,
          moduleId: 'fiction.immersion',
          safeBoundary: .5,
          chapters: const [
            FictionBackfillChapter(
              href: 'one.xhtml',
              title: '第一章',
              startProgress: .1,
              endProgress: .2,
            ),
          ],
          loadChapter: (_) async => '两人在车站相遇。',
          generate: (_) async => jsonEncode([
            {
              'kind': 'event',
              'payload': {
                'title': '车站相遇',
                'summary': '两人第一次见面',
                'participants': ['甲', '乙'],
              },
            },
            {
              'kind': 'relationship',
              'payload': {'from': '甲'},
            },
          ]),
          sessionId: 'session',
          ingestedAt: 9999,
          existingArtifacts: existing,
        );

    final first = await build();
    final second = await build(existing: first);

    expect(first, hasLength(1));
    expect(first.single.kind, ReadingArtifactKinds.event);
    expect(first.single.id, startsWith('fiction-backfill-'));
    expect(second, isEmpty);
  });

  test('candidate validator rejects unsupported evidence and adds provenance',
      () async {
    final artifacts = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: .5,
      chapters: const [
        FictionBackfillChapter(
          href: 'one.xhtml',
          title: '第一章',
          startProgress: .1,
          endProgress: .2,
        ),
      ],
      loadChapter: (_) async => '第五伦走进屋内。',
      generate: (_) async => jsonEncode([
        {
          'kind': 'character',
          'payload': {'name': '第五伦', 'evidence': '第五伦走进屋内'}
        },
        {
          'kind': 'character',
          'payload': {'name': '县宰', 'evidence': '正文中不存在'}
        },
      ]),
      validateCandidate: ({
        required kind,
        required payload,
        required chapterContent,
      }) async {
        final evidence = payload['evidence']?.toString() ?? '';
        return chapterContent.contains(evidence) ? payload : null;
      },
      artifactMetadata: const {'pipelineVersion': 1},
      sessionId: 'session',
      ingestedAt: 1,
    );

    expect(artifacts, hasLength(1));
    expect(artifacts.single.payload['name'], '第五伦');
    expect(artifacts.single.payload['pipelineVersion'], 1);
    expect(artifacts.single.sourceTextSnapshot, '第五伦走进屋内');
  });

  test('backfill respects the persisted artifact coverage lower bound',
      () async {
    final loaded = <String>[];
    final artifacts = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: .5,
      fromProgress: .3,
      chapters: const [
        FictionBackfillChapter(
          href: 'unseen-prefix.xhtml',
          title: '本机未读前文',
          startProgress: .1,
          endProgress: .2,
        ),
        FictionBackfillChapter(
          href: 'local-range.xhtml',
          title: '本机起点之后',
          startProgress: .35,
          endProgress: .45,
        ),
      ],
      loadChapter: (href) async {
        loaded.add(href);
        return '正文';
      },
      generate: (_) async => jsonEncode([
        {
          'kind': 'event',
          'payload': {'title': '事件'}
        }
      ]),
      sessionId: 'session',
      ingestedAt: 1,
    );

    expect(loaded, ['local-range.xhtml']);
    expect(artifacts, hasLength(1));
    expect(artifacts.single.sourceProgress, .35);
  });

  test('batches chapters and emits resumable checkpoints after success',
      () async {
    var requests = 0;
    final completed = <String>[];
    final savedCheckpoints = <ReadingArtifact>[];
    final artifacts = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: .8,
      batchSize: 2,
      chapters: const [
        FictionBackfillChapter(
            href: 'one.xhtml', title: '一', startProgress: .1, endProgress: .2),
        FictionBackfillChapter(
            href: 'two.xhtml', title: '二', startProgress: .2, endProgress: .3),
      ],
      loadChapter: (_) async => '同一批正文',
      generate: (_) async {
        requests++;
        return jsonEncode([
          {
            'chapterHref': 'one.xhtml',
            'items': [
              {
                'kind': 'event',
                'payload': {'title': '一中的事件'}
              }
            ]
          },
          {
            'chapterHref': 'two.xhtml',
            'items': [
              {
                'kind': 'event',
                'payload': {'title': '二中的事件'}
              }
            ]
          },
        ]);
      },
      sessionId: 'session',
      ingestedAt: 1,
      onBatchCompleted: ({
        required artifacts,
        required checkpoints,
        required completedChapters,
        required totalChapters,
      }) async {
        savedCheckpoints.addAll(checkpoints);
        completed.addAll(checkpoints.map((item) => item.chapterHref!));
        expect(artifacts, hasLength(2));
        expect(completedChapters, 2);
        expect(totalChapters, 2);
      },
    );

    expect(requests, 1);
    expect(artifacts, hasLength(2));
    expect(completed, ['one.xhtml', 'two.xhtml']);

    final resumed = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: .8,
      batchSize: 2,
      chapters: const [
        FictionBackfillChapter(
            href: 'one.xhtml', title: '一', startProgress: .1, endProgress: .2),
        FictionBackfillChapter(
            href: 'two.xhtml', title: '二', startProgress: .2, endProgress: .3),
      ],
      loadChapter: (_) async => '同一批正文',
      generate: (_) async {
        requests++;
        return '[]';
      },
      sessionId: 'session',
      ingestedAt: 2,
      existingArtifacts: savedCheckpoints,
    );
    expect(resumed, isEmpty);
    expect(requests, 1);
  });

  test('persists successful concurrent batches before surfacing a failure',
      () async {
    final savedCheckpoints = <ReadingArtifact>[];
    await expectLater(
      fictionBackfillService.build(
        bookId: 7,
        moduleId: 'fiction.immersion',
        safeBoundary: 1,
        batchSize: 1,
        concurrency: 2,
        chapters: const [
          FictionBackfillChapter(
              href: 'one.xhtml',
              title: '一',
              startProgress: .1,
              endProgress: .2),
          FictionBackfillChapter(
              href: 'two.xhtml',
              title: '二',
              startProgress: .2,
              endProgress: .3),
        ],
        loadChapter: (_) async => '正文',
        generate: (prompt) async {
          if (prompt.contains('two.xhtml')) {
            throw StateError('persistent failure');
          }
          return jsonEncode([
            {
              'chapterHref': 'one.xhtml',
              'items': [
                {
                  'kind': 'event',
                  'payload': {'title': '已完成'}
                }
              ]
            }
          ]);
        },
        sessionId: 'session',
        ingestedAt: 1,
        onBatchCompleted: ({
          required artifacts,
          required checkpoints,
          required completedChapters,
          required totalChapters,
        }) async {
          savedCheckpoints.addAll(checkpoints);
        },
      ),
      throwsA(isA<StateError>()),
    );
    expect(savedCheckpoints, hasLength(1));
    expect(savedCheckpoints.single.chapterHref, 'one.xhtml');
  });

  test('does not checkpoint an incomplete model batch', () async {
    var callbackCalled = false;
    await expectLater(
      fictionBackfillService.build(
        bookId: 1,
        moduleId: 'fiction.immersion',
        safeBoundary: 1,
        batchSize: 2,
        chapters: const [
          FictionBackfillChapter(
              href: 'one.xhtml',
              title: '一',
              startProgress: .1,
              endProgress: .2),
          FictionBackfillChapter(
              href: 'two.xhtml',
              title: '二',
              startProgress: .2,
              endProgress: .3),
        ],
        loadChapter: (_) async => '正文',
        generate: (_) async => jsonEncode([
          {'chapterHref': 'one.xhtml', 'items': []}
        ]),
        sessionId: 'session',
        ingestedAt: 1,
        onBatchCompleted: ({
          required artifacts,
          required checkpoints,
          required completedChapters,
          required totalChapters,
        }) async {
          callbackCalled = true;
        },
      ),
      throwsFormatException,
    );
    expect(callbackCalled, isFalse);
  });

  test('splits a rejected multi-chapter batch and preserves both chapters',
      () async {
    var requests = 0;
    final completed = <String>[];
    final artifacts = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: 1,
      batchSize: 2,
      chapters: const [
        FictionBackfillChapter(
            href: 'one.xhtml', title: '一', startProgress: .1, endProgress: .2),
        FictionBackfillChapter(
            href: 'two.xhtml', title: '二', startProgress: .2, endProgress: .3),
      ],
      loadChapter: (_) async => '正文',
      generate: (prompt) async {
        requests++;
        if (prompt.contains('one.xhtml') && prompt.contains('two.xhtml')) {
          throw StateError('combined request rejected');
        }
        final href = prompt.contains('one.xhtml') ? 'one.xhtml' : 'two.xhtml';
        return jsonEncode([
          {
            'chapterHref': href,
            'items': [
              {
                'kind': 'event',
                'payload': {'title': '$href 的事件'}
              }
            ]
          }
        ]);
      },
      sessionId: 'session',
      ingestedAt: 1,
      onBatchCompleted: ({
        required artifacts,
        required checkpoints,
        required completedChapters,
        required totalChapters,
      }) async {
        completed.addAll(checkpoints.map((item) => item.chapterHref!));
      },
    );

    expect(requests, 3);
    expect(artifacts, hasLength(2));
    expect(completed, ['one.xhtml', 'two.xhtml']);
  });

  test('retries a transient single-chapter failure once', () async {
    var requests = 0;
    final artifacts = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: 1,
      chapters: const [
        FictionBackfillChapter(
            href: 'one.xhtml', title: '一', startProgress: .1, endProgress: .2),
      ],
      loadChapter: (_) async => '正文',
      generate: (_) async {
        requests++;
        if (requests == 1) throw StateError('transient rejection');
        return jsonEncode([
          {
            'chapterHref': 'one.xhtml',
            'items': [
              {
                'kind': 'character',
                'payload': {'name': '第五伦'}
              }
            ]
          }
        ]);
      },
      sessionId: 'session',
      ingestedAt: 1,
    );

    expect(requests, 2);
    expect(artifacts.single.payload['name'], '第五伦');
  });

  test('carries a compact character catalog across sequential batches',
      () async {
    final prompts = <String>[];
    final artifacts = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: 1,
      batchSize: 1,
      concurrency: 1,
      chapters: const [
        FictionBackfillChapter(
            href: 'one.xhtml', title: '一', startProgress: .1, endProgress: .2),
        FictionBackfillChapter(
            href: 'two.xhtml', title: '二', startProgress: .2, endProgress: .3),
      ],
      loadChapter: (_) async => '第五伦登场。',
      generate: (prompt) async {
        prompts.add(prompt);
        final href = prompt.contains('two.xhtml') ? 'two.xhtml' : 'one.xhtml';
        return jsonEncode([
          {
            'chapterHref': href,
            'items': [
              {
                'kind': 'character',
                'payload': {'name': '第五伦'}
              }
            ]
          }
        ]);
      },
      sessionId: 'session',
      ingestedAt: 1,
    );

    expect(prompts, hasLength(2));
    expect(prompts.first, isNot(contains('已建档人物')));
    expect(prompts.last, contains('已建档人物'));
    expect(prompts.last, contains('第五伦'));
    expect(artifacts, hasLength(1));
  });

  test('prompt requests compact characters and canonical-name endpoints',
      () async {
    late String prompt;
    await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: 1,
      chapters: const [
        FictionBackfillChapter(
            href: 'one.xhtml', title: '一', startProgress: .1, endProgress: .2),
      ],
      loadChapter: (_) async => '第五伦与第五霸交谈。',
      generate: (value) async {
        prompt = value;
        return jsonEncode([
          {'chapterHref': 'one.xhtml', 'items': []}
        ]);
      },
      sessionId: 'session',
      ingestedAt: 1,
    );

    expect(prompt, contains('每个人物在同一批次只输出一次'));
    expect(prompt, contains('必须使用人物完整规范姓名'));
    expect(prompt, contains('数字姓'));
    expect(prompt, contains('不得自行推断为同宗'));
    expect(prompt, contains('按原文保留'));
    expect(prompt, contains('摘要保持一句话'));
  });

  test('hybrid extraction splits an oversized chapter but checkpoints once',
      () async {
    final prompts = <String>[];
    final savedCheckpoints = <ReadingArtifact>[];
    final content = List.filled(900, '第五伦走进屋内。').join('\n');

    await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: 1,
      chapters: const [
        FictionBackfillChapter(
          href: 'long.xhtml',
          title: '长章',
          startProgress: .1,
          endProgress: .2,
        ),
      ],
      loadChapter: (_) async => content,
      generate: (prompt) async {
        prompts.add(prompt);
        return jsonEncode([
          {'chapterHref': 'long.xhtml', 'items': []}
        ]);
      },
      validateCandidate: ({
        required kind,
        required payload,
        required chapterContent,
      }) async =>
          payload,
      maxInputCharacters: 4000,
      sessionId: 'session',
      ingestedAt: 1,
      onBatchCompleted: ({
        required artifacts,
        required checkpoints,
        required completedChapters,
        required totalChapters,
      }) async {
        savedCheckpoints.addAll(checkpoints);
        expect(completedChapters, 1);
        expect(totalChapters, 1);
      },
    );

    expect(prompts.length, greaterThan(1));
    expect(
      prompts.every((prompt) => prompt.length < 7000),
      isTrue,
    );
    expect(savedCheckpoints, hasLength(1));
    expect(savedCheckpoints.single.chapterHref, 'long.xhtml');
  });

  test('malformed long chapter response retries smaller inputs once', () async {
    var requests = 0;
    final promptLengths = <int>[];
    final savedCheckpoints = <ReadingArtifact>[];
    final content = List.filled(500, '第五伦走进屋内。').join('\n');

    await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: 1,
      chapters: const [
        FictionBackfillChapter(
          href: 'retry.xhtml',
          title: '重试章',
          startProgress: .1,
          endProgress: .2,
        ),
      ],
      loadChapter: (_) async => content,
      generate: (prompt) async {
        requests++;
        promptLengths.add(prompt.length);
        if (requests == 1) return 'not json';
        return jsonEncode([
          {'chapterHref': 'retry.xhtml', 'items': []}
        ]);
      },
      sessionId: 'session',
      ingestedAt: 1,
      onBatchCompleted: ({
        required artifacts,
        required checkpoints,
        required completedChapters,
        required totalChapters,
      }) async {
        savedCheckpoints.addAll(checkpoints);
      },
    );

    expect(requests, 3);
    expect(promptLengths.skip(1).every((length) => length < promptLengths[0]),
        isTrue);
    expect(savedCheckpoints, hasLength(1));
  });

  test('reprocesses a checkpointed chapter when its content changes', () async {
    final savedCheckpoints = <ReadingArtifact>[];
    var requests = 0;

    Future<void> build(String content,
        {Iterable<ReadingArtifact> existing = const []}) async {
      await fictionBackfillService.build(
        bookId: 1,
        moduleId: 'fiction.immersion',
        safeBoundary: 1,
        chapters: const [
          FictionBackfillChapter(
              href: 'one.xhtml',
              title: '一',
              startProgress: .1,
              endProgress: .2),
        ],
        loadChapter: (_) async => content,
        generate: (_) async {
          requests++;
          return '[]';
        },
        sessionId: 'session',
        ingestedAt: 1,
        existingArtifacts: existing,
        onBatchCompleted: ({
          required artifacts,
          required checkpoints,
          required completedChapters,
          required totalChapters,
        }) async {
          savedCheckpoints.addAll(checkpoints);
        },
      );
    }

    await build('旧正文');
    await build('新正文', existing: savedCheckpoints);
    expect(requests, 2);
  });

  test('reprocesses checkpoints created by an older extractor version',
      () async {
    final oldCheckpoint = ReadingArtifact(
      id: 'old-checkpoint',
      bookId: 1,
      moduleId: 'fiction.immersion',
      kind: ReadingArtifactKinds.backfillCheckpoint,
      payload: {
        'contentHash':
            'b5d4045c3f466fa91fe2cc6abe79232a1a57cdf104f7a26e716e0a1e2789df78',
        'extractorVersion': 2,
      },
      chapterHref: 'one.xhtml',
      sourceProgress: .1,
      visibleFromProgress: .1,
      ingestedAt: 1,
      createdAt: 1,
      updatedAt: 1,
    );
    var requests = 0;

    await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: .5,
      chapters: const [
        FictionBackfillChapter(
          href: 'one.xhtml',
          title: '第一章',
          startProgress: .1,
          endProgress: .2,
        ),
      ],
      loadChapter: (_) async => 'ABC',
      generate: (_) async {
        requests++;
        return '[]';
      },
      sessionId: 'session',
      ingestedAt: 2,
      existingArtifacts: [oldCheckpoint],
    );

    expect(requests, 1);
  });

  test('persists collection work scope on artifacts and checkpoints', () async {
    final savedCheckpoints = <ReadingArtifact>[];
    final artifacts = await fictionBackfillService.build(
      bookId: 1,
      moduleId: 'fiction.immersion',
      safeBoundary: .5,
      chapters: const [
        FictionBackfillChapter(
          href: 'white-night-1.xhtml',
          title: '第一章',
          startProgress: .1,
          endProgress: .2,
          workId: 'work-white-night',
          workTitle: '白夜行',
        ),
      ],
      loadChapter: (_) async => '唐泽雪穗走进教室。',
      generate: (_) async => jsonEncode([
        {
          'kind': 'character',
          'payload': {'name': '唐泽雪穗'}
        }
      ]),
      sessionId: 'session',
      ingestedAt: 1,
      onBatchCompleted: ({
        required artifacts,
        required checkpoints,
        required completedChapters,
        required totalChapters,
      }) async {
        savedCheckpoints.addAll(checkpoints);
      },
    );

    expect(artifacts.single.payload['workId'], 'work-white-night');
    expect(artifacts.single.payload['workTitle'], '白夜行');
    expect(savedCheckpoints.single.payload['workId'], 'work-white-night');
  });
}
