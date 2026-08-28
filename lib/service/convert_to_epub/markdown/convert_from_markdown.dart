import 'dart:io';

import 'package:anx_reader/service/convert_to_epub/create_epub.dart';
import 'package:anx_reader/service/convert_to_epub/section.dart';
import 'package:anx_reader/service/convert_to_epub/txt/convert_from_txt.dart';
import 'package:anx_reader/utils/log/common.dart';
import 'package:path/path.dart' as path;

Future<File> convertFromMarkdown(File file) async {
  final fallbackTitle = path.basenameWithoutExtension(file.path);
  final source = readFileWithEncoding(file)
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');
  final document = parseMarkdownDocument(source, fallbackTitle: fallbackTitle);
  AnxLog.info(
    'ConvertMarkdown: title=${document.title} sections=${document.sections.length}',
  );
  return createEpub(document.title, 'Unknown', document.sections);
}

class MarkdownDocument {
  const MarkdownDocument({required this.title, required this.sections});

  final String title;
  final List<Section> sections;
}

MarkdownDocument parseMarkdownDocument(
  String source, {
  required String fallbackTitle,
}) {
  final lines = source.split('\n');
  final headings = <_Heading>[];
  String? fenceMarker;
  for (var i = 0; i < lines.length; i++) {
    final trimmed = lines[i].trimLeft();
    if (fenceMarker != null) {
      if (trimmed.startsWith(fenceMarker)) fenceMarker = null;
      continue;
    }
    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      fenceMarker = trimmed.substring(0, 3);
      continue;
    }
    final match = RegExp(r'^(#{1,6})\s+(.+?)\s*#*\s*$').firstMatch(trimmed);
    if (match != null) {
      headings.add(_Heading(
        line: i,
        endLine: i,
        level: match.group(1)!.length,
        title: _plainInlineText(match.group(2)!),
      ));
      continue;
    }
    if (i + 1 < lines.length && trimmed.isNotEmpty) {
      final setext = RegExp(r'^\s*(=+|-+)\s*$').firstMatch(lines[i + 1]);
      if (setext != null) {
        headings.add(_Heading(
          line: i,
          endLine: i + 1,
          level: setext.group(1)!.startsWith('=') ? 1 : 2,
          title: _plainInlineText(trimmed),
        ));
        i++;
      }
    }
  }

  final title = headings
      .firstWhere(
        (heading) => heading.level == 1,
        orElse: () => headings.isEmpty
            ? _Heading(
                line: -1,
                endLine: -1,
                level: 1,
                title: fallbackTitle,
              )
            : headings.first,
      )
      .title;
  final sections = <Section>[];

  if (headings.isEmpty) {
    sections.add(Section(
      fallbackTitle,
      source.trim(),
      1,
      xhtmlContent: markdownBlocksToXhtml(lines),
    ));
  } else {
    final intro = lines.sublist(0, headings.first.line);
    if (intro.any((line) => line.trim().isNotEmpty)) {
      sections.add(Section(
        fallbackTitle,
        intro.join('\n').trim(),
        1,
        xhtmlContent: markdownBlocksToXhtml(intro),
      ));
    }
    for (var i = 0; i < headings.length; i++) {
      final heading = headings[i];
      final end = i + 1 < headings.length ? headings[i + 1].line : lines.length;
      final body = lines.sublist(heading.endLine + 1, end);
      sections.add(Section(
        heading.title,
        body.join('\n').trim(),
        heading.level,
        xhtmlContent: markdownBlocksToXhtml(body),
      ));
    }
  }

  return MarkdownDocument(
    title: title.trim().isEmpty ? fallbackTitle : title.trim(),
    sections: sections,
  );
}

String markdownBlocksToXhtml(List<String> lines) {
  final output = <String>[];
  var index = 0;
  while (index < lines.length) {
    final line = lines[index];
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      index++;
      continue;
    }

    if (trimmed.startsWith('```') || trimmed.startsWith('~~~')) {
      final marker = trimmed.substring(0, 3);
      final language = trimmed.substring(3).trim();
      final code = <String>[];
      index++;
      while (index < lines.length && !lines[index].trim().startsWith(marker)) {
        code.add(lines[index]);
        index++;
      }
      if (index < lines.length) index++;
      final className = RegExp(r'^[A-Za-z0-9_+-]+$').hasMatch(language)
          ? ' class="language-${_escapeXml(language)}"'
          : '';
      output.add(
          '<pre><code$className>${_escapeXml(code.join('\n'))}</code></pre>');
      continue;
    }

    if (_isTableHeader(lines, index)) {
      final rows = <List<String>>[_splitTableRow(lines[index])];
      index += 2;
      while (index < lines.length &&
          lines[index].contains('|') &&
          lines[index].trim().isNotEmpty) {
        rows.add(_splitTableRow(lines[index]));
        index++;
      }
      final header = rows.first
          .map((cell) => '<th>${markdownInlineToXhtml(cell)}</th>')
          .join();
      final body = rows.skip(1).map((row) {
        return '<tr>${row.map((cell) => '<td>${markdownInlineToXhtml(cell)}</td>').join()}</tr>';
      }).join();
      output.add(
          '<div class="table-wrap"><table><thead><tr>$header</tr></thead><tbody>$body</tbody></table></div>');
      continue;
    }

    final listMatch =
        RegExp(r'^\s*(?:([-+*])|(\d+)[.)])\s+(.+)$').firstMatch(line);
    if (listMatch != null) {
      final ordered = listMatch.group(2) != null;
      final tag = ordered ? 'ol' : 'ul';
      final items = <String>[];
      while (index < lines.length) {
        final match = RegExp(r'^\s*(?:([-+*])|(\d+)[.)])\s+(.+)$')
            .firstMatch(lines[index]);
        if (match == null || (match.group(2) != null) != ordered) break;
        var value = match.group(3)!;
        final task = RegExp(r'^\[([ xX])\]\s+(.*)$').firstMatch(value);
        if (task != null) {
          value =
              '${task.group(1)!.trim().isEmpty ? '☐' : '☑'} ${task.group(2)!}';
        }
        items.add('<li>${markdownInlineToXhtml(value)}</li>');
        index++;
      }
      output.add('<$tag>${items.join()}</$tag>');
      continue;
    }

    if (trimmed.startsWith('>')) {
      final quote = <String>[];
      while (index < lines.length && lines[index].trimLeft().startsWith('>')) {
        quote.add(lines[index].trimLeft().replaceFirst(RegExp(r'^>\s?'), ''));
        index++;
      }
      output.add(
          '<blockquote>${markdownInlineToXhtml(quote.join('\n')).replaceAll('\n', '<br />')}</blockquote>');
      continue;
    }

    if (RegExp(r'^\s{0,3}([-*_])(?:\s*\1){2,}\s*$').hasMatch(line)) {
      output.add('<hr />');
      index++;
      continue;
    }

    final paragraph = <String>[];
    while (index < lines.length && lines[index].trim().isNotEmpty) {
      if (paragraph.isNotEmpty && _startsBlock(lines, index)) break;
      paragraph.add(lines[index].trim());
      index++;
    }
    output.add(
        '<p>${markdownInlineToXhtml(paragraph.join('\n')).replaceAll('\n', '<br />')}</p>');
  }
  return output.join('\n');
}

bool _startsBlock(List<String> lines, int index) {
  final line = lines[index].trimLeft();
  return line.startsWith('```') ||
      line.startsWith('~~~') ||
      line.startsWith('>') ||
      RegExp(r'^\s*(?:[-+*]|\d+[.)])\s+').hasMatch(lines[index]) ||
      _isTableHeader(lines, index);
}

bool _isTableHeader(List<String> lines, int index) {
  if (index + 1 >= lines.length || !lines[index].contains('|')) return false;
  final separator = lines[index + 1].trim();
  return RegExp(r'^\|?\s*:?-{3,}:?\s*(?:\|\s*:?-{3,}:?\s*)+\|?$')
      .hasMatch(separator);
}

List<String> _splitTableRow(String line) {
  var value = line.trim();
  if (value.startsWith('|')) value = value.substring(1);
  if (value.endsWith('|')) value = value.substring(0, value.length - 1);
  return value.split(RegExp(r'(?<!\\)\|')).map((cell) => cell.trim()).toList();
}

String markdownInlineToXhtml(String value) {
  final code = <String>[];
  var protected = value.replaceAllMapped(RegExp(r'`([^`\n]+)`'), (match) {
    code.add('<code>${_escapeXml(match.group(1)!)}</code>');
    return '\u0000${code.length - 1}\u0000';
  });
  protected = _escapeXml(protected);
  protected = protected.replaceAllMapped(
    RegExp(r'!\[([^\]]*)\]\([^\s)]+(?:\s+&quot;[^&]*&quot;)?\)'),
    (match) => '<span class="image-alt">[${match.group(1)}]</span>',
  );
  protected = protected.replaceAllMapped(
    RegExp(r'\[([^\]]+)\]\(([^\s)]+)(?:\s+&quot;[^&]*&quot;)?\)'),
    (match) {
      final href = _safeHref(match.group(2)!);
      return href == null
          ? match.group(1)!
          : '<a href="$href">${match.group(1)}</a>';
    },
  );
  protected = protected
      .replaceAllMapped(RegExp(r'\*\*(.+?)\*\*|__(.+?)__'),
          (match) => '<strong>${match.group(1) ?? match.group(2)}</strong>')
      .replaceAllMapped(
          RegExp(r'~~(.+?)~~'), (match) => '<del>${match.group(1)}</del>')
      .replaceAllMapped(
          RegExp(r'(?<!\*)\*([^*\n]+)\*(?!\*)|(?<!_)_([^_\n]+)_(?!_)'),
          (match) => '<em>${match.group(1) ?? match.group(2)}</em>');
  return protected.replaceAllMapped(RegExp('\u0000(\\d+)\u0000'),
      (match) => code[int.parse(match.group(1)!)]);
}

String? _safeHref(String value) {
  final lower = value.toLowerCase();
  if (lower.startsWith('https://') ||
      lower.startsWith('http://') ||
      lower.startsWith('mailto:') ||
      value.startsWith('#')) {
    return value;
  }
  return null;
}

String _plainInlineText(String value) => value
    .replaceAll(RegExp(r'!\[([^\]]*)\]\([^)]*\)'), r'$1')
    .replaceAll(RegExp(r'\[([^\]]+)\]\([^)]*\)'), r'$1')
    .replaceAll(RegExp(r'[`*_~]'), '')
    .trim();

String _escapeXml(String value) => value
    .replaceAll('&', '&amp;')
    .replaceAll('<', '&lt;')
    .replaceAll('>', '&gt;')
    .replaceAll('"', '&quot;')
    .replaceAll("'", '&apos;');

class _Heading {
  const _Heading({
    required this.line,
    required this.endLine,
    required this.level,
    required this.title,
  });

  final int line;
  final int endLine;
  final int level;
  final String title;
}
