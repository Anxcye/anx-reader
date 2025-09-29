import 'dart:math' as math;

import 'package:anx_reader/service/convert_to_epub/section.dart';

String _escapeXml(String value) {
  return value
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');
}

String _indent(int level) => '  ' * (level + 1);

String generateNestedToc(List<Section> sections) {
  if (sections.isEmpty) {
    return '';
  }

  final tocItems = List.generate(sections.length, (index) {
    final section = sections[index];
    final fallbackTitle = section.content.trim().split('\n').firstWhere(
          (line) => line.trim().isNotEmpty,
          orElse: () => 'Section ${index + 1}',
        );
    final title = section.title.trim().isNotEmpty
        ? section.title.trim()
        : fallbackTitle.trim();

    final level = section.level < 1 ? 1 : section.level;

    return _TocItem(title: title, index: index, level: level);
  });

  final positiveLevels = tocItems
      .where((item) => item.level > 0)
      .map((item) => item.level)
      .toList();

  if (positiveLevels.isNotEmpty) {
    final baseLevel = positiveLevels.reduce(math.min);
    for (final item in tocItems) {
      item.level = item.level - baseLevel + 1;
    }
  } else {
    for (final item in tocItems) {
      item.level = 1;
    }
  }

  final buffer = StringBuffer();
  final levelStack = <int>[];
  var playOrder = 1;

  for (final item in tocItems) {
    final level = item.level.clamp(1, 6);

    while (levelStack.isNotEmpty && level <= levelStack.last) {
      final closingLevel = levelStack.removeLast();
      buffer.writeln('${_indent(closingLevel)}</navPoint>');
    }

    buffer.write(_indent(level));
    buffer.writeln(
        '<navPoint id="navPoint-${item.index}" playOrder="$playOrder">');
    buffer.write(_indent(level));
    buffer.writeln(
        '  <navLabel><text>${_escapeXml(item.title)}</text></navLabel>');
    buffer.write(_indent(level));
    buffer.writeln('  <content src="xhtml/${item.index}.xhtml"/>');
    levelStack.add(level);
    playOrder += 1;
  }

  while (levelStack.isNotEmpty) {
    final closingLevel = levelStack.removeLast();
    buffer.writeln('${_indent(closingLevel)}</navPoint>');
  }

  return buffer.toString();
}

class _TocItem {
  _TocItem({
    required this.title,
    required this.index,
    required this.level,
  });

  final String title;
  final int index;
  int level;
}
