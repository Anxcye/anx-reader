import 'dart:io';

import 'package:anx_reader/service/convert_to_epub/markdown/convert_from_markdown.dart';
import 'package:archive/archive_io.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('maps headings to EPUB sections and preserves common formatting', () {
    const source = '''# Reading Notes

Intro with **bold**, *emphasis*, `inline code`, and [safe](https://example.com?a=1&b=2).

## Checklist

- [x] Finished
- [ ] Review

> A quoted idea.

| Item | Value |
| --- | ---: |
| One | 1 |

```dart
print('<safe>');
```
''';

    final document = parseMarkdownDocument(
      source,
      fallbackTitle: 'notes',
    );

    expect(document.title, 'Reading Notes');
    expect(document.sections, hasLength(2));
    expect(document.sections[0].title, 'Reading Notes');
    expect(document.sections[0].level, 1);
    expect(document.sections[1].title, 'Checklist');
    expect(document.sections[1].level, 2);

    final intro = document.sections[0].xhtmlContent!;
    expect(intro, contains('<strong>bold</strong>'));
    expect(intro, contains('<em>emphasis</em>'));
    expect(intro, contains('<code>inline code</code>'));
    expect(intro, contains('href="https://example.com?a=1&amp;b=2"'));

    final checklist = document.sections[1].xhtmlContent!;
    expect(
        checklist, contains('<ul><li>☑ Finished</li><li>☐ Review</li></ul>'));
    expect(checklist, contains('<blockquote>A quoted idea.</blockquote>'));
    expect(checklist, contains('<table>'));
    expect(checklist, contains('class="language-dart"'));
    expect(checklist, contains('&lt;safe&gt;'));
  });

  test('does not execute raw HTML or unsafe links and degrades images', () {
    final document = parseMarkdownDocument(
      '<script>alert(1)</script>\n\n[bad](javascript:alert(1)) ![cover](local.png)',
      fallbackTitle: 'safe',
    );
    final xhtml = document.sections.single.xhtmlContent!;

    expect(xhtml, contains('&lt;script&gt;alert(1)&lt;/script&gt;'));
    expect(xhtml, isNot(contains('<script>')));
    expect(xhtml, isNot(contains('javascript:')));
    expect(xhtml, contains('<span class="image-alt">[cover]</span>'));
  });

  test('supports Setext headings and ignores headings inside code fences', () {
    const source = '''Document Title
==============

Section
-------

~~~markdown
# Not a chapter
~~~
''';
    final document = parseMarkdownDocument(source, fallbackTitle: 'fallback');

    expect(document.title, 'Document Title');
    expect(document.sections.map((section) => section.title),
        ['Document Title', 'Section']);
    expect(document.sections.map((section) => section.level), [1, 2]);
    expect(document.sections.last.xhtmlContent, contains('# Not a chapter'));
  });

  test('converts a Markdown file into a readable EPUB package', () async {
    final tempDir = await Directory.systemTemp.createTemp('anx_md_test_');
    addTearDown(() => tempDir.delete(recursive: true));
    const channel = MethodChannel('plugins.flutter.io/path_provider');
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async => tempDir.path);
    addTearDown(() {
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          .setMockMethodCallHandler(channel, null);
    });
    final markdown = File('${tempDir.path}/Guide.md');
    await markdown.writeAsString('# Guide\n\n## Start\n\nHello.');

    final epub = await convertFromMarkdown(markdown);
    addTearDown(() async {
      if (await epub.exists()) await epub.delete();
    });
    final archive = ZipDecoder().decodeBytes(await epub.readAsBytes());
    final names = archive.files.map((file) => file.name).toSet();

    expect(names, contains('mimetype'));
    expect(names, contains('OEBPS/content.opf'));
    expect(names, contains('OEBPS/style.css'));
    expect(names, contains('OEBPS/xhtml/0.xhtml'));
    expect(names, contains('OEBPS/xhtml/1.xhtml'));

    final chapter =
        archive.files.firstWhere((file) => file.name == 'OEBPS/xhtml/1.xhtml');
    final chapterText = String.fromCharCodes(chapter.content as List<int>);
    expect(chapterText, contains('<h2>Start</h2>'));
    expect(chapterText, contains('<p>Hello.</p>'));
    expect(chapterText, contains('href="../style.css"'));
  });
}
