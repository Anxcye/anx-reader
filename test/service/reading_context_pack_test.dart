import 'package:anx_reader/models/book_wiki.dart';
import 'package:anx_reader/models/reading_context_pack.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('context pack hides nodes beyond the reading boundary', () {
    const pack = ReadingContextPack(
      bookId: 1,
      nodes: [
        ReadingContextNode(
          id: 'chapter:1',
          bookId: 1,
          kind: ReadingContextNodeKinds.chapter,
          title: '第一章',
          summary: '已读内容',
          visibleFromProgress: .2,
          sourceProgress: .2,
        ),
        ReadingContextNode(
          id: 'chapter:2',
          bookId: 1,
          kind: ReadingContextNodeKinds.chapter,
          title: '第二章',
          summary: '后文内容',
          visibleFromProgress: .8,
          sourceProgress: .8,
        ),
      ],
    );

    final context = pack.toPromptContext(visibleAtProgress: .5);
    expect(context, contains('第一章'));
    expect(context, isNot(contains('第二章')));
  });

  test('prompt context is bounded and keeps query matches first', () {
    const pack = ReadingContextPack(
      bookId: 1,
      nodes: [
        ReadingContextNode(
          id: 'a',
          bookId: 1,
          kind: ReadingContextNodeKinds.entity,
          title: '无关条目',
          summary: '普通内容',
          sortKey: '1',
        ),
        ReadingContextNode(
          id: 'b',
          bookId: 1,
          kind: ReadingContextNodeKinds.entity,
          title: '目标人物',
          summary: '关系内容',
          sortKey: '2',
        ),
      ],
    );

    final context = pack.toPromptContext(
      visibleAtProgress: 1,
      query: '目标人物',
      maxCharacters: 64,
    );
    expect(context, contains('目标人物'));
    expect(context.length, lessThanOrEqualTo(64));
  });

  test('chapter context prefers matching sources without crossing the boundary', () {
    const pack = ReadingContextPack(
      bookId: 1,
      nodes: [
        ReadingContextNode(
          id: 'a',
          bookId: 1,
          kind: ReadingContextNodeKinds.chapter,
          title: '第一章摘要',
          sourceRefs: [
            BookWikiSourceRef(
              id: 's1',
              entryId: 'a',
              bookId: 1,
              chapterHref: 'chapter-1.xhtml',
              chapterTitle: '第一章',
              sourceProgress: .2,
              createdAt: 1,
            ),
          ],
          visibleFromProgress: .2,
        ),
        ReadingContextNode(
          id: 'b',
          bookId: 1,
          kind: ReadingContextNodeKinds.chapter,
          title: '后文摘要',
          sourceRefs: [
            BookWikiSourceRef(
              id: 's2',
              entryId: 'b',
              bookId: 1,
              chapterHref: 'chapter-2.xhtml',
              chapterTitle: '第二章',
              sourceProgress: .8,
              createdAt: 1,
            ),
          ],
          visibleFromProgress: .8,
        ),
      ],
    );

    final context = pack.toPromptContext(
      visibleAtProgress: .5,
      chapterHref: 'chapter-1.xhtml#body',
    );
    expect(context, contains('第一章摘要'));
    expect(context, isNot(contains('后文摘要')));
  });
}
